#!/usr/bin/env bash
# Reports Native Assets sunset-clock streak from history.jsonl (M2-03).
set -euo pipefail

HISTORY_PATH="docs/sunset-clock/history.jsonl"
TARGET_WEEKS=8
REQUIRE_STREAK=false
GITHUB_REPO=""

usage() {
  echo "Usage: $0 [--history PATH] [--weeks N] [--require-streak] [--github OWNER/REPO]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --history)
      HISTORY_PATH="${2:?}"
      shift 2
      ;;
    --weeks)
      TARGET_WEEKS="${2:?}"
      shift 2
      ;;
    --require-streak)
      REQUIRE_STREAK=true
      shift
      ;;
    --github)
      GITHUB_REPO="${2:?}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

if [[ ! -f "$HISTORY_PATH" ]]; then
  echo "Native Assets sunset clock (PRD §3.3 bullet 2)"
  echo "Target: ${TARGET_WEEKS} consecutive scheduled green weeks"
  echo "Current streak: 0 weeks"
  echo "Status: NO DATA (history file missing: $HISTORY_PATH)"
  if [[ "$REQUIRE_STREAK" == true ]]; then
    exit 1
  fi
  exit 0
fi

REPORT=$(
  python3 - "$HISTORY_PATH" "$TARGET_WEEKS" <<'PY'
import json
import sys

history_path = sys.argv[1]
target_weeks = int(sys.argv[2])

rows = []
with open(history_path, encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if line:
            rows.append(json.loads(line))

if not rows:
    print("Native Assets sunset clock (PRD §3.3 bullet 2)")
    print(f"Target: {target_weeks} consecutive scheduled green weeks")
    print("Current streak: 0 weeks")
    print("Status: NO DATA")
    sys.exit(0)

rows.sort(key=lambda row: (row.get("week", ""), row.get("recorded_at", "")))

streak = 0
streak_weeks = []
for row in reversed(rows):
    conclusion = row.get("matrix_conclusion", "")
    if conclusion == "success":
        streak += 1
        streak_weeks.insert(0, row.get("week", "?"))
    else:
        break

last = rows[-1]
last_week = last.get("week", "?")
last_conclusion = last.get("matrix_conclusion", "?")
last_run = last.get("workflow_run_id", "?")

print("Native Assets sunset clock (PRD §3.3 bullet 2)")
print(f"Target: {target_weeks} consecutive scheduled green weeks")
if streak > 0:
    span = f"{streak_weeks[0]} .. {streak_weeks[-1]}" if streak > 1 else streak_weeks[0]
    print(f"Current streak: {streak} week(s) ({span})")
else:
    print("Current streak: 0 weeks")
print(f"Last run: {last_week} {last_conclusion} (run {last_run})")

if streak >= target_weeks:
    print("Status: MET")
else:
    remaining = target_weeks - streak
    print(f"Status: IN PROGRESS ({remaining} week(s) remaining)")
PY
)

echo "$REPORT"

if [[ "$REQUIRE_STREAK" == true ]]; then
  if echo "$REPORT" | grep -q '^Status: MET$'; then
    exit 0
  fi
  exit 1
fi

if [[ -n "$GITHUB_REPO" ]] && command -v gh >/dev/null 2>&1; then
  echo
  echo "Recent scheduled workflow runs ($GITHUB_REPO):"
  gh run list \
    --repo "$GITHUB_REPO" \
    --workflow="Native Assets Sunset Clock (PRD §3.3)" \
    --limit 5 || true
fi
