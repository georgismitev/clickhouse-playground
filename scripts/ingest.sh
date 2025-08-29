#!/usr/bin/env bash
set -euo pipefail

# Minimal one-liner ingest (no timing)
cd "$(cd "$(dirname "$0")/.." && pwd)"

FILE="log.csv"
TARGET_TABLE="${TARGET_TABLE:-logs_db.logs}"

if [ ! -f "$FILE" ]; then
  echo "File '$FILE' not found." >&2
  exit 2
fi

# Start ClickHouse server and ensure cleanup
if ! command -v clickhouse >/dev/null 2>&1; then
  echo "clickhouse binary not found in PATH." >&2
  exit 3
fi

echo "Killing any running ClickHouse server processes (best-effort)..."
pkill -f "clickhouse server" 2>/dev/null || true
sleep 0.2

echo "Starting ClickHouse server (background)..."
clickhouse server --config-file=./config.xml >/dev/null 2>&1 &
SERVER_PID=$!

cleanup() {
  echo "Stopping ClickHouse server (PID $SERVER_PID)..."
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" || true
    sleep 1
    if kill -0 "$SERVER_PID" 2>/dev/null; then
      kill -9 "$SERVER_PID" || true
    fi
  fi
}
trap cleanup EXIT

echo "Waiting for ClickHouse HTTP (127.0.0.1:8123) to become available..."
for i in {1..150}; do
  if curl -sS 'http://127.0.0.1:8123/?query=SELECT+1' >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

echo "Running: cat $FILE | clickhouse client --query=\"INSERT INTO $TARGET_TABLE FORMAT CSV\""
cat "$FILE" | clickhouse client --query="INSERT INTO $TARGET_TABLE FORMAT CSV"
# Prefer the client's exit code (second element of PIPESTATUS). If missing, fall back to the producer.
rc=${PIPESTATUS[1]:-${PIPESTATUS[0]}}
exit $rc
