#!/usr/bin/env bash
# Upserts one weekly Native Assets sunset-clock sample (M2-03).
# Usage: record_sunset_clock.sh <matrix_conclusion> [history_path]
set -euo pipefail

CONCLUSION="${1:-}"
HISTORY_PATH="${2:-docs/sunset-clock/history.jsonl}"

if [[ -z "$CONCLUSION" ]]; then
  echo "Usage: $0 <success|failure|cancelled> [history_path]" >&2
  exit 1
fi

mkdir -p "$(dirname "$HISTORY_PATH")"

python3 - "$CONCLUSION" "$HISTORY_PATH" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

conclusion = sys.argv[1]
history_path = sys.argv[2]

now = datetime.now(timezone.utc)
week = now.strftime("%G-W%V")
recorded_at = now.replace(microsecond=0).isoformat().replace("+00:00", "Z")

run_id = os.environ.get("GITHUB_RUN_ID", "local")
run_url = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
repo = os.environ.get("GITHUB_REPOSITORY", "local/repo")
if run_id != "local":
    run_url = f"{run_url}/{repo}/actions/runs/{run_id}"

event = os.environ.get("GITHUB_EVENT_NAME", "manual")
workflow = os.environ.get(
    "GITHUB_WORKFLOW", "Native Assets Sunset Clock (PRD §3.3)"
)

entry = {
    "week": week,
    "recorded_at": recorded_at,
    "event": event,
    "workflow": workflow,
    "workflow_run_id": int(run_id) if run_id.isdigit() else run_id,
    "run_url": run_url,
    "matrix_conclusion": conclusion,
    "flutter_versions": ["3.47.4", "3.44.0", "3.38.1"],
    "matrix_cells": 9,
}

rows = []
if os.path.exists(history_path):
    with open(history_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))

rows = [row for row in rows if row.get("week") != week]
rows.append(entry)
rows.sort(key=lambda row: (row.get("week", ""), row.get("recorded_at", "")))

with open(history_path, "w", encoding="utf-8") as fh:
    for row in rows:
        fh.write(json.dumps(row, separators=(",", ":")) + "\n")

print(json.dumps(entry, indent=2))
PY
