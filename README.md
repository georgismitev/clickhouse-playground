Generate logs
----------

Small utility to create a CSV "log" file populated with random, row-coherent data.

Usage examples:

Create default-sized file (100 MB):

    python3 generate_log.py

Create a 10 KB test file:

    python3 generate_log.py --size 10KB --output test_log.csv -v

Create a 5 GB file:

    python3 generate_log.py --size 5GB --output log_5GB.csv -v

ClickHouse
----------

    alias chs='clickhouse server --config-file=./config.xml'
    alias chc='clickhouse client'

Note: to persist these aliases, add the `export` and `alias` lines to your shell rc file (for example `~/.bashrc` or `~/.zshrc`). After adding them, reload your shell with one of the following commands:

    source ~/.bashrc

or for zsh:

    source ~/.zshrc

Alternatively, start a new terminal session to pick up the changes.

Columns produced: id, created_at, updated_at, username_md5, first_name, last_name, bio

Migrations
----------

This repo includes simple SQL migrations under `migrations/`:

- `001_create_database.sql` — creates `logs_db` database
- `002_create_log_table.sql` — creates `logs_db.logs` table matching the generated CSV

To apply migrations (requires `clickhouse client` in PATH):

```bash
./scripts/apply-migrations.sh
```

The script runs each `.sql` in `migrations/` in lexicographic order.