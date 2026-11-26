#!/usr/bin/env python3
"""Validate and normalize the nine Olist CSVs for SQL Server BULK INSERT.

This script never drops or repairs source rows. It validates headers, required
values, primary keys, review scores, and foreign-key relationships; only when
all checks pass does it write UTF-8 CSVs with LF line endings and a manifest.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path

@dataclass(frozen=True)
class Dataset:
    filename: str
    required_columns: tuple[str, ...]
    key_columns: tuple[str, ...] = ()
    nonempty_columns: tuple[str, ...] = ()

DATASETS = (
    Dataset("olist_customers_dataset.csv", ("customer_id", "customer_unique_id", "customer_zip_code_prefix", "customer_city", "customer_state"), ("customer_id",), ("customer_id", "customer_unique_id")),
    Dataset("olist_orders_dataset.csv", ("order_id", "customer_id", "order_status", "order_purchase_timestamp", "order_approved_at", "order_delivered_carrier_date", "order_delivered_customer_date", "order_estimated_delivery_date"), ("order_id",), ("order_id", "customer_id", "order_status", "order_purchase_timestamp", "order_estimated_delivery_date")),
    Dataset("olist_order_items_dataset.csv", ("order_id", "order_item_id", "product_id", "seller_id", "shipping_limit_date", "price", "freight_value"), ("order_id", "order_item_id"), ("order_id", "product_id", "seller_id")),
    Dataset("olist_order_payments_dataset.csv", ("order_id", "payment_sequential", "payment_type", "payment_installments", "payment_value"), ("order_id", "payment_sequential"), ("order_id", "payment_type")),
    # Review records intentionally have no unique source key: duplicate review_id
    # and multiple reviews per order occur in the published dataset.
    Dataset("olist_order_reviews_dataset.csv", ("review_id", "order_id", "review_score", "review_comment_title", "review_comment_message", "review_creation_date", "review_answer_timestamp"), (), ("review_id", "order_id", "review_score")),
    Dataset("olist_products_dataset.csv", ("product_id", "product_category_name", "product_name_lenght", "product_description_lenght", "product_photos_qty", "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"), ("product_id",), ("product_id",)),
    Dataset("olist_sellers_dataset.csv", ("seller_id", "seller_zip_code_prefix", "seller_city", "seller_state"), ("seller_id",), ("seller_id",)),
    Dataset("olist_geolocation_dataset.csv", ("geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng", "geolocation_city", "geolocation_state"), (), ("geolocation_zip_code_prefix",)),
    Dataset("product_category_name_translation.csv", ("product_category_name", "product_category_name_english"), ("product_category_name",), ("product_category_name", "product_category_name_english")),
)

class ValidationError(Exception):
    pass

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def validate(raw_dir: Path) -> tuple[dict[str, dict[str, object]], dict[str, set[str]]]:
    summaries: dict[str, dict[str, object]] = {}
    keys: dict[str, set[str]] = {}
    errors: list[str] = []
    for spec in DATASETS:
        path = raw_dir / spec.filename
        if not path.is_file():
            errors.append(f"{spec.filename}: file is missing")
            continue
        try:
            with path.open("r", encoding="utf-8-sig", newline="") as handle:
                reader = csv.DictReader(handle)
                header = reader.fieldnames
                if header is None:
                    errors.append(f"{spec.filename}: header is missing")
                    continue
                if len(header) != len(set(header)):
                    errors.append(f"{spec.filename}: duplicate header names")
                missing = sorted(set(spec.required_columns) - set(header))
                if missing:
                    errors.append(f"{spec.filename}: missing columns {', '.join(missing)}")
                    continue
                if tuple(header) != spec.required_columns:
                    errors.append(f"{spec.filename}: columns must match SQL Server import order exactly")
                    continue
                seen: set[str] = set()
                duplicates = 0
                row_count = 0
                null_counts = {column: 0 for column in spec.nonempty_columns}
                bad_scores = 0
                for line_number, row in enumerate(reader, start=2):
                    row_count += 1
                    for column in spec.nonempty_columns:
                        if not (row.get(column) or "").strip():
                            null_counts[column] += 1
                    if spec.key_columns:
                        key = "\x1f".join((row.get(c) or "").strip() for c in spec.key_columns)
                        if any(not part for part in key.split("\x1f")):
                            errors.append(f"{spec.filename}:{line_number}: blank key {spec.key_columns}")
                        elif key in seen:
                            duplicates += 1
                        else:
                            seen.add(key)
                    if spec.filename == "olist_order_reviews_dataset.csv":
                        try:
                            if not 1 <= int(row["review_score"]) <= 5:
                                bad_scores += 1
                        except (TypeError, ValueError):
                            bad_scores += 1
                for column, count in null_counts.items():
                    if count:
                        errors.append(f"{spec.filename}: {count} blank values in required field {column}")
                if duplicates:
                    errors.append(f"{spec.filename}: {duplicates} duplicate primary/composite keys")
                if bad_scores:
                    errors.append(f"{spec.filename}: {bad_scores} review scores outside integer range 1-5")
                summaries[spec.filename] = {
                    "rows": row_count,
                    "sha256": sha256(path),
                    "duplicate_key_rows": duplicates,
                    "blank_required_values": null_counts,
                    "review_score_errors": bad_scores,
                }
                if spec.key_columns:
                    keys[spec.filename] = seen
        except (OSError, UnicodeError, csv.Error) as exc:
            errors.append(f"{spec.filename}: cannot read CSV ({exc})")

    relations = (
        ("olist_orders_dataset.csv", "customer_id", "olist_customers_dataset.csv"),
        ("olist_order_items_dataset.csv", "order_id", "olist_orders_dataset.csv"),
        ("olist_order_items_dataset.csv", "product_id", "olist_products_dataset.csv"),
        ("olist_order_items_dataset.csv", "seller_id", "olist_sellers_dataset.csv"),
        ("olist_order_payments_dataset.csv", "order_id", "olist_orders_dataset.csv"),
        ("olist_order_reviews_dataset.csv", "order_id", "olist_orders_dataset.csv"),
    )
    for child_file, column, parent_file in relations:
        child_path = raw_dir / child_file
        if not child_path.is_file() or parent_file not in keys:
            continue
        parents = keys[parent_file]
        try:
            with child_path.open("r", encoding="utf-8-sig", newline="") as handle:
                for line_number, row in enumerate(csv.DictReader(handle), start=2):
                    value = (row.get(column) or "").strip()
                    if value and value not in parents:
                        errors.append(f"{child_file}:{line_number}: {column} references unknown key in {parent_file}")
                        if len(errors) >= 100:
                            errors.append("Further validation errors omitted.")
                            break
        except (OSError, UnicodeError, csv.Error) as exc:
            errors.append(f"{child_file}: relationship scan failed ({exc})")

    if errors:
        raise ValidationError("\n".join(errors[:100]))
    return summaries, keys

def normalize(raw_dir: Path, output_dir: Path, summaries: dict[str, dict[str, object]]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".olist-prepare-", dir=output_dir) as temp_name:
        temp_dir = Path(temp_name)
        for spec in DATASETS:
            source_path, staged_path = raw_dir / spec.filename, temp_dir / spec.filename
            with source_path.open("r", encoding="utf-8-sig", newline="") as source, staged_path.open("w", encoding="utf-8", newline="") as target:
                reader = csv.reader(source)
                writer = csv.writer(target, lineterminator="\n")
                writer.writerows(reader)
            summaries[spec.filename]["prepared_sha256"] = sha256(staged_path)
        for spec in DATASETS:
            os.replace(temp_dir / spec.filename, output_dir / spec.filename)
        manifest = {
            "tool": "python/prepare_olist.py",
            "format": "UTF-8 CSV, LF line endings",
            "source_directory": str(raw_dir),
            "tables": summaries,
            "notes": [
                "Source rows are preserved; no rows are dropped or corrected.",
                "Review rows may repeat review_id and order_id by design.",
                "Inspect and resolve reported validation failures in source data before loading.",
            ],
        }
        manifest_path = temp_dir / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        os.replace(manifest_path, output_dir / "manifest.json")

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("data/raw"), help="folder containing the nine original Olist CSV files")
    parser.add_argument("--output", type=Path, default=Path("data/processed/sql_server"), help="normalized SQL Server import folder")
    args = parser.parse_args()
    raw_dir, output_dir = args.input.resolve(), args.output.resolve()
    if raw_dir == output_dir or raw_dir in output_dir.parents:
        parser.error("output must not be the raw input directory or a child of it")
    try:
        summaries, _ = validate(raw_dir)
        normalize(raw_dir, output_dir, summaries)
    except ValidationError as exc:
        parser.exit(1, f"Validation failed; no prepared files were written:\n{exc}\n")
    print(f"Validated and prepared {len(DATASETS)} files in {output_dir}")
    print(f"Manifest: {output_dir / 'manifest.json'}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
