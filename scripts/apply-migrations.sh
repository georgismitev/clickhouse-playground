#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATIONS_DIR="$ROOT_DIR/migrations"

CLICKHOUSE_CLIENT="$(command -v clickhouse || true)"
if [[ -z "$CLICKHOUSE_CLIENT" ]]; then
  echo "clickhouse client not found in PATH. Please install ClickHouse or add it to PATH." >&2
  exit 1
fi

echo "Applying migrations from $MIGRATIONS_DIR"
for f in "$MIGRATIONS_DIR"/*.sql; do
  echo "-- Applying $(basename "$f")"
  "$CLICKHOUSE_CLIENT" --multiquery --query="$(cat "$f")"
done

echo "Migrations applied."
