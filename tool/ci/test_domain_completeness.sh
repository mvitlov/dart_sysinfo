#!/usr/bin/env bash
# Self-check for domain-completeness (M3-02).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

run_dart() {
  if command -v fvm >/dev/null 2>&1; then
    fvm dart "$@"
  else
    dart "$@"
  fi
}

run_dart test tool/test/domain_completeness_test.dart
run_dart run tool/ci/check_domain_completeness.dart
echo "All domain-completeness checks passed."
