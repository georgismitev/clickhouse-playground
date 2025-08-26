# generate_log.py

Small utility to create a CSV "log" file populated with random, row-coherent data.

Usage examples:

Create default-sized file (100 MB):

    python3 generate_log.py

Create a 10 KB test file:

    python3 generate_log.py --size 10KB --output test_log.csv -v

Create a 5 GB file:

    python3 generate_log.py --size 5GB --output log_5GB.csv -v

Start ClickHouse (example):

    alias chs='clickhouse server --config-file=./config.xml'
    alias chc='clickhouse client'

Note: to persist these aliases, add the `export` and `alias` lines to your shell rc file (for example `~/.bashrc` or `~/.zshrc`). After adding them, reload your shell with one of the following commands:

    source ~/.bashrc

or for zsh:

    source ~/.zshrc

Alternatively, start a new terminal session to pick up the changes.

Columns produced: id, created_at, updated_at, username_md5, first_name, last_name, bio