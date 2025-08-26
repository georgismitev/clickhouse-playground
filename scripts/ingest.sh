
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

FILE="log.csv"
if [ ! -f "$FILE" ]; then
  echo "File '$FILE' not found in repo root." >&2
  exit 2
fi

# start clickhouse server in background using local config
SERVER_CMD="clickhouse server --config-file=./config.xml"
echo "Starting ClickHouse server..."
$SERVER_CMD &
SERVER_PID=$!
echo "ClickHouse server PID: $SERVER_PID"

cleanup() {
  echo "Stopping ClickHouse server (PID $SERVER_PID)..."
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" || true
    sleep 3
    if kill -0 "$SERVER_PID" 2>/dev/null; then
      echo "Server did not stop, killing..."
      kill -9 "$SERVER_PID" || true
    fi
  fi
}
trap cleanup EXIT

# wait until HTTP is ready
echo "Waiting for ClickHouse HTTP (127.0.0.1:8123) to become available..."
ready=0
for i in {1..150}; do
  if curl -sS 'http://127.0.0.1:8123/?query=SELECT+1' >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.2
done
if [ "$ready" -ne 1 ]; then
  echo "ClickHouse HTTP did not become ready in time" >&2
  exit 4
fi

# Detect header: assume header if first field contains non-digits
first_line=$(head -n1 "$FILE")
first_field=${first_line%%,*}
if [[ "$first_field" =~ [^0-9] ]]; then
  has_header=1
else
  has_header=0
fi

total_lines=$(wc -l < "$FILE")
if [ "$has_header" -eq 1 ]; then
  rows=$((total_lines - 1))
else
  rows=$total_lines
fi

echo "Ingesting $rows rows from $FILE... (header=$has_header)"

START=$(date +%s.%N)

# perform insertion using clickhouse client (native) which connects to the server we started
clickhouse client --query="INSERT INTO logs_db.logs FORMAT CSV" < "$FILE"
RC=$?

END=$(date +%s.%N)
ELAPSED=$(echo "$END - $START" | bc -l)

if [ "$rows" -le 0 ]; then
  echo "No rows to insert."
  exit 3
fi

ROWS_PER_SEC=$(echo "$rows / $ELAPSED" | bc -l)
SECS_PER_10K=$(echo "$ELAPSED * 10000 / $rows" | bc -l)

printf "Inserted %d rows in %.3f s (%.0f rows/s)\n" "$rows" "$ELAPSED" "$ROWS_PER_SEC"

cmp=$(echo "$SECS_PER_10K <= 1.0" | bc -l)
if [ "$cmp" -eq 1 ]; then
  printf "Result: %.3f sec per 10k rows — ✅\n" "$SECS_PER_10K"
else
  printf "Result: %.3f sec per 10k rows — 😭\n" "$SECS_PER_10K"
fi

exit $RC
