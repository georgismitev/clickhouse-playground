-- 002_create_log_table.sql
-- Creates a `logs` table compatible with the generated CSV format.

CREATE TABLE IF NOT EXISTS logs_db.logs (
    id UInt64,
    created_at DateTime,
    updated_at DateTime,
    username_md5 String,
    first_name String,
    last_name String,
    bio String
) ENGINE = MergeTree()
ORDER BY (id)
PARTITION BY toYYYYMM(created_at)
;
