#!/usr/bin/env bash
# Domain-completeness CI check (M3-02).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
if command -v fvm >/dev/null 2>&1; then
  exec fvm dart run tool/ci/check_domain_completeness.dart "$@"
fi
exec dart run tool/ci/check_domain_completeness.dart "$@"
