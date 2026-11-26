import csv
import json
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from prepare_olist import DATASETS, ValidationError, normalize, validate

SAMPLES = {
    "olist_customers_dataset.csv": [["c1", "u1", "12345", "city", "ST"]],
    "olist_orders_dataset.csv": [["o1", "c1", "delivered", "2017-01-01 00:00:00", "", "", "", "2017-01-02 00:00:00"]],
    "olist_order_items_dataset.csv": [["o1", "1", "p1", "s1", "2017-01-02 00:00:00", "10.00", "2.00"]],
    "olist_order_payments_dataset.csv": [["o1", "1", "credit_card", "1", "12.00"]],
    "olist_order_reviews_dataset.csv": [["r1", "o1", "5", "", "", "2017-01-03 00:00:00", "2017-01-04 00:00:00"],
                                       ["r1", "o1", "4", "", "", "2017-01-03 00:00:00", "2017-01-04 00:00:00"]],
    "olist_products_dataset.csv": [["p1", "cat", "1", "2", "1", "100", "10", "10", "10"]],
    "olist_sellers_dataset.csv": [["s1", "12345", "city", "ST"]],
    "olist_geolocation_dataset.csv": [["12345", "-1.0", "-2.0", "city", "ST"]],
    "product_category_name_translation.csv": [["cat", "category"]],
}

class PrepareOlistTests(unittest.TestCase):
    def make_input(self, root: Path) -> Path:
        source = root / "raw"
        source.mkdir()
        for spec in DATASETS:
            with (source / spec.filename).open("w", encoding="utf-8", newline="") as handle:
                writer = csv.writer(handle)
                writer.writerow(spec.required_columns)
                writer.writerows(SAMPLES[spec.filename])
        return source

    def test_validates_and_normalizes_all_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            raw = self.make_input(root)
            output = root / "processed"
            summary, _ = validate(raw)
            normalize(raw, output, summary)
            self.assertEqual(len(list(output.glob("*.csv"))), 9)
            self.assertTrue((output / "manifest.json").is_file())
            manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(manifest["tables"]["olist_order_reviews_dataset.csv"]["rows"], 2)
            self.assertEqual(manifest["tables"]["olist_order_reviews_dataset.csv"]["duplicate_key_rows"], 0)
            self.assertEqual((output / "olist_customers_dataset.csv").read_bytes().count(b"\r\n"), 0)

    def test_duplicate_primary_key_fails_without_output(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            raw = self.make_input(root)
            path = raw / "olist_customers_dataset.csv"
            with path.open("a", encoding="utf-8", newline="") as handle:
                csv.writer(handle).writerow(SAMPLES[path.name][0])
            output = root / "processed"
            with self.assertRaisesRegex(ValidationError, "duplicate primary/composite keys"):
                summary, _ = validate(raw)
                normalize(raw, output, summary)
            self.assertFalse(output.exists())

    def test_orphan_foreign_key_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            raw = self.make_input(root)
            path = raw / "olist_orders_dataset.csv"
            with path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.writer(handle)
                writer.writerow(DATASETS[1].required_columns)
                writer.writerow(["o1", "missing_customer", "delivered", "2017-01-01", "2017-01-02"])
            with self.assertRaisesRegex(ValidationError, "references unknown key"):
                validate(raw)

    def test_reordered_or_extra_header_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            raw = self.make_input(root)
            path = raw / "olist_customers_dataset.csv"
            with path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.writer(handle)
                writer.writerow(list(reversed(DATASETS[0].required_columns)))
                writer.writerow(list(reversed(SAMPLES[path.name][0])))
            with self.assertRaisesRegex(ValidationError, "import order exactly"):
                validate(raw)

    def test_invalid_review_score_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            raw = self.make_input(root)
            path = raw / "olist_order_reviews_dataset.csv"
            with path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.writer(handle)
                writer.writerow(DATASETS[4].required_columns)
                writer.writerow(["r1", "o1", "6", "", "", "", ""])
            with self.assertRaisesRegex(ValidationError, "review scores outside"):
                validate(raw)

if __name__ == "__main__":
    unittest.main()
