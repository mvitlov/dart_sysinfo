# Native Assets sunset clock (PRD §3.3)

Tracks evidence for **PRD §3.3 bullet 2**: the Native Assets CI matrix must be
green for **eight consecutive weeks of scheduled CI** before Cargokit can sunset
(M5).

## Canonical clock

| Source | Role |
|---|---|
| [`.github/workflows/native-assets-sunset-clock.yaml`](../../.github/workflows/native-assets-sunset-clock.yaml) | Weekly scheduled sample (Monday 06:00 UTC) + `workflow_dispatch` |
| [`history.jsonl`](history.jsonl) | Append-only weekly pass/fail records (bot-maintained on `main`) |
| [`tool/ci/sunset_clock_report.sh`](../../tool/ci/sunset_clock_report.sh) | Computes consecutive green weeks |

**Streak semantics:**

- Only **scheduled** / **workflow_dispatch** samples in `history.jsonl` count.
- PR `native-assets` job results are visible in GitHub Actions but do **not**
  update this file or reset the streak.
- A scheduled run with matrix `failure` or `cancelled` breaks the streak.

## JSONL schema

Each line is one JSON object:

```json
{
  "week": "2026-W38",
  "recorded_at": "2026-09-18T06:12:00Z",
  "event": "schedule",
  "workflow": "Native Assets Sunset Clock (PRD §3.3)",
  "workflow_run_id": 123456789,
  "run_url": "https://github.com/ORG/REPO/actions/runs/123456789",
  "matrix_conclusion": "success",
  "flutter_versions": ["3.47.4", "3.44.0", "3.38.1"],
  "matrix_cells": 9
}
```

Re-runs in the same ISO week **replace** that week's row (upsert by `week`).

## Query commands

```bash
# Streak from committed history
bash tool/ci/sunset_clock_report.sh

# Fail if < 8 consecutive green weeks (future M5 gate)
bash tool/ci/sunset_clock_report.sh --require-streak --weeks 8

# Recent scheduled runs (GitHub CLI)
gh run list --workflow="Native Assets Sunset Clock (PRD §3.3)" --limit 20

# Manual sample
gh workflow run "Native Assets Sunset Clock (PRD §3.3)"
```

## Matrix scope note

The clock tracks the current **9-cell** Native Assets matrix (same as
`flutter-build`: latest tier all 5 platforms; min/intermediate Android+Linux
only). PRD §3.3 also mentions minimum SDK on all 5 platforms — expand the
matrix in a follow-up if M5-01 requires it.

## Flutter release milestones

[`flutter-release-milestones.json`](flutter-release-milestones.json) is a
maintainer-updated companion for the “two consecutive stable Flutter releases”
half of §3.3. M5-01 reviews it alongside the weekly streak.

## Bot commits

History updates commit only under `docs/sunset-clock/`. Root CI ignores that path
(`paths-ignore`) so bot pushes do not re-trigger the full merge gate.

**Repo setting:** allow `github-actions[bot]` to push to `main` (Settings → Actions → General → Workflow permissions).
