#!/usr/bin/env bash
# Self-check for sunset_clock_report.sh streak logic (M2-03).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE="$ROOT/tool/ci/testdata/sunset_clock_history.jsonl"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

cp "$FIXTURE" "$TMP/history.jsonl"

report() {
  bash "$ROOT/tool/ci/sunset_clock_report.sh" --history "$TMP/history.jsonl" "$@"
}

echo "== test: streak met (8 consecutive successes) =="
OUT="$(report --weeks 8)"
echo "$OUT"
echo "$OUT" | grep -q '^Status: MET$'

echo "== test: streak broken after failure fixture =="
python3 - "$TMP/history.jsonl" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
rows.append({
    "week": "2026-W39",
    "recorded_at": "2026-09-25T06:00:00Z",
    "event": "schedule",
    "workflow": "Native Assets Sunset Clock (PRD §3.3)",
    "workflow_run_id": 999,
    "run_url": "https://example.invalid/runs/999",
    "matrix_conclusion": "failure",
    "flutter_versions": ["3.47.4", "3.44.0", "3.38.1"],
    "matrix_cells": 9,
})
path.write_text("\n".join(json.dumps(row, separators=(",", ":")) for row in rows) + "\n")
PY
OUT="$(report --weeks 8)"
echo "$OUT"
echo "$OUT" | grep -q '^Current streak: 0 weeks$'

echo "== test: --require-streak exits 1 when not met =="
if report --weeks 8 --require-streak; then
  echo "ERROR: expected exit 1" >&2
  exit 1
fi

echo "All sunset_clock_report tests passed."
