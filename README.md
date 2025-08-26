# generate_log.py

Small utility to create a CSV "log" file populated with random, row-coherent data.

Usage examples:

Create default-sized file (100 MB):

    python3 generate_log.py

Create a 10 KB test file:

    python3 generate_log.py --size 10KB --output test_log.csv -v

Columns produced: id, created_at, updated_at, username_md5, first_name, last_name, bio