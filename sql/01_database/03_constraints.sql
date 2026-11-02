USE Olist_Ecommerce_Analytics;
GO

/*
Core constraints are declared with the table definitions in
sql/01_database/02_create_tables.sql. This script audits existing constraints;
it does not add duplicate or incomplete fragments.
*/

SELECT
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    kc.name AS constraint_name,
    kc.type_desc AS constraint_type,
    kc.is_disabled,
    kc.is_not_trusted
FROM sys.key_constraints AS kc
INNER JOIN sys.tables AS t ON t.object_id = kc.parent_object_id
WHERE SCHEMA_NAME(t.schema_id) = 'core'

UNION ALL

SELECT
    SCHEMA_NAME(t.schema_id), t.name, fk.name, 'FOREIGN_KEY',
    fk.is_disabled, fk.is_not_trusted
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
WHERE SCHEMA_NAME(t.schema_id) = 'core'

UNION ALL

SELECT
    SCHEMA_NAME(t.schema_id), t.name, cc.name, 'CHECK_CONSTRAINT',
    cc.is_disabled, cc.is_not_trusted
FROM sys.check_constraints AS cc
INNER JOIN sys.tables AS t ON t.object_id = cc.parent_object_id
WHERE SCHEMA_NAME(t.schema_id) = 'core'
ORDER BY schema_name, table_name, constraint_type, constraint_name;
GO