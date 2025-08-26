#!/usr/bin/env python3
"""Generate a CSV "log file" with random but row-coherent data.

Columns: id, created_at, updated_at, username_md5, first_name, last_name, bio

Defaults to creating a 100 MB file if no size is given.
"""
import argparse
import csv
import hashlib
import random
import sys
from datetime import datetime, timedelta


SAMPLE_FIRST = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
]

SAMPLE_LAST = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
]

JOBS = ["engineer", "designer", "teacher", "nurse", "manager", "developer", "writer", "analyst"]
CITIES = ["New York", "San Francisco", "Chicago", "Austin", "Seattle", "Boston", "Denver", "Miami"]
HOBBIES = [
    "photography", "hiking", "gardening", "reading", "travelling", "cooking", "cycling", "painting"
]


def parse_size(size_str: str) -> int:
    """Parse a size like '100MB', '1G', '512K', or raw number of bytes."""
    s = size_str.strip().upper()
    if s.endswith("BYTES"):
        s = s[:-5].strip()
    multipliers = {"B": 1, "K": 1024, "KB": 1024, "M": 1024 ** 2, "MB": 1024 ** 2, "G": 1024 ** 3, "GB": 1024 ** 3}
    # find suffix
    for suf in sorted(multipliers.keys(), key=len, reverse=True):
        if s.endswith(suf):
            num = float(s[: -len(suf)])
            return int(num * multipliers[suf])
    # fallback: no suffix, assume bytes
    return int(float(s))


def make_bio(first: str, last: str, job: str, city: str, hobbies: list, rid: int) -> str:
    """Create a relatively long bio string related to the row values."""
    picks = random.sample(hobbies, k=min(3, len(hobbies)))
    age = random.randint(20, 75)
    sentences = [
        f"{first} {last} (id={rid}) is a {age}-year-old {job} based in {city}.",
        f"They enjoy {', '.join(picks)}, and often spend weekends practicing {picks[0]}.",
        f"{first} has worked as a {job} for several years and is known among colleagues for being reliable.",
        f"Contact: username_md5 is included in the record; this bio ties to that user.",
    ]
    # Add some filler to make blobs larger and more realistic
    filler = " ".join([
        "Experienced professional with a passion for continuous learning.",
        "Enjoys collaborative projects and mentoring others.",
        "Active in local community events and volunteer work.",
    ])
    return " ".join(sentences) + " " + filler


def md5_username(first: str, last: str, rid: int) -> str:
    s = f"{first.lower()}.{last.lower()}.{rid}"
    return hashlib.md5(s.encode("utf-8")).hexdigest()


def gen_row(rid: int):
    first = random.choice(SAMPLE_FIRST)
    last = random.choice(SAMPLE_LAST)
    job = random.choice(JOBS)
    city = random.choice(CITIES)
    created_offset_days = random.randint(0, 365 * 5)
    created = datetime.utcnow() - timedelta(days=created_offset_days, seconds=random.randint(0, 86400))
    # updated is after created
    updated = created + timedelta(days=random.randint(0, 365), seconds=random.randint(0, 86400))
    username_hash = md5_username(first, last, rid)
    bio = make_bio(first, last, job, city, HOBBIES, rid)
    # ClickHouse DateTime expects 'YYYY-MM-DD hh:mm:ss' (no fractional seconds or timezone)
    created_s = created.strftime("%Y-%m-%d %H:%M:%S")
    updated_s = updated.strftime("%Y-%m-%d %H:%M:%S")
    return {
        "id": rid,
        "created_at": created_s,
        "updated_at": updated_s,
        "username_md5": username_hash,
        "first_name": first,
        "last_name": last,
        "bio": bio,
    }


def generate_file(path: str, target_bytes: int, verbose: bool = False):
    header = ["id", "created_at", "updated_at", "username_md5", "first_name", "last_name", "bio"]
    rows = 0
    # open text mode so csv handles quoting, but measure bytes via buffer
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        f.flush()
        # ensure we write at least one row
        rid = 1
        while True:
            row = gen_row(rid)
            writer.writerow([row[c] for c in header])
            rows += 1
            rid += 1
            if rows % 1000 == 0:
                f.flush()
                if verbose:
                    print(f"written rows={rows} bytes={f.buffer.tell()}")
            # check size
            if f.buffer.tell() >= target_bytes:
                if verbose:
                    print(f"target reached: {f.buffer.tell()} >= {target_bytes}")
                break
        # final flush
        f.flush()
    return rows


def main(argv=None):
    p = argparse.ArgumentParser(description="Generate a CSV log file of approximate size.")
    p.add_argument("--size", "-s", default="100MB", help="Target size (e.g. 100MB, 1G, 512K). Default: 100MB")
    # Output filename is hardcoded to 'log.csv' per workspace convention
    args = p.parse_args(argv)

    try:
        target = parse_size(args.size)
    except Exception:
        print("Failed to parse size. Use formats like '100MB' or raw bytes.")
        sys.exit(2)

    if target <= 0:
        print("Size must be > 0")
        sys.exit(2)

    output_path = "log.csv"
    # Always verbose per workspace convention
    print(f"Generating file '{output_path}' target={target} bytes")

    rows = generate_file(output_path, target, verbose=True)

    print(f"Done. Wrote {rows} rows to {output_path}")


if __name__ == "__main__":
    main()
