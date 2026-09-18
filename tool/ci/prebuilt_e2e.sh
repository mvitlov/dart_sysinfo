#!/usr/bin/env bash
# Self-contained prebuilt e2e for linux-x64 (M3-06).
#
# GitHub Actions assumptions:
# - Flutter is on PATH via subosito/flutter-action (FLUTTER_ROOT is set).
# - FVM is NOT installed on CI runners; resolve flutter/dart explicitly.
# - Rust may be installed earlier in the same job; consumer phase must not
#   compile from source (DART_SYSINFO_PREBUILT=1 + no Rust + hook guard).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIST="${PREBUILT_DIST:-$ROOT/dist/prebuilt/linux-x64}"
if [[ "$DIST" != /* ]]; then
  DIST="$ROOT/$DIST"
fi
LIB="$DIST/libdart_sysinfo_native.so"
MANIFEST="$ROOT/.tmp/prebuilt-e2e-manifest.json"
REPO="${PREBUILT_REPOSITORY:-mvitlov/dart_sysinfo}"

_resolve_flutter_tools() {
  if [[ -n "${FLUTTER_ROOT:-}" && -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
    FLUTTER=("${FLUTTER_ROOT}/bin/flutter")
    DART=("${FLUTTER_ROOT}/bin/dart")
  elif command -v fvm >/dev/null 2>&1; then
    FLUTTER=(fvm flutter)
    DART=(fvm dart)
  elif command -v flutter >/dev/null 2>&1; then
    FLUTTER=(flutter)
    DART=(dart)
  else
    echo "ERROR: flutter not found (set FLUTTER_ROOT or add flutter to PATH)" >&2
    exit 127
  fi
}

_path_without_rust() {
  local IFS=':'
  local entry cleaned=""
  for entry in ${PATH:-}; do
    case "$entry" in
      *cargo*|*rustup*|*/.cargo/bin*) continue ;;
    esac
    cleaned="${cleaned:+$cleaned:}$entry"
  done
  printf '%s' "$cleaned"
}

_prepare_consumer_env() {
  export DART_SYSINFO_PREBUILT=1
  export DART_SYSINFO_FROM_SOURCE=0
  export DART_SYSINFO_PREBUILT_MANIFEST="$MANIFEST"
  export DART_SYSINFO_SKIP_ATTESTATION=1
  # Keep Flutter/Dart; drop Rust from PATH and probe locations.
  export PATH="$(_path_without_rust)"
  unset CARGO_HOME RUSTUP_HOME
  export HOME="${PREBUILT_E2E_HOME:-/tmp/prebuilt-e2e-home}"
  mkdir -p "$HOME"
}

_resolve_flutter_tools

cd "$ROOT"

if [[ "${SKIP_PREBUILT_BUILD:-0}" != "1" ]]; then
  bash tool/release/build_linux_prebuilt.sh "$DIST"
fi

if [[ ! -f "$LIB" ]]; then
  echo "ERROR: prebuilt library not found at $LIB" >&2
  exit 1
fi

SHA256="$(shasum -a 256 "$LIB" | awk '{print tolower($1)}')"
FILE_URL="file://$LIB"

mkdir -p "$(dirname "$MANIFEST")"
cat > "$MANIFEST" <<EOF
{
  "packageVersion": "0.1.0",
  "abi": 3,
  "artifacts": {
    "linux-x64": {
      "fileName": "libdart_sysinfo_native.so",
      "sha256": "$SHA256",
      "url": "$FILE_URL",
      "attestation": {
        "kind": "github-artifact-attestation",
        "repository": "$REPO",
        "digestAlgorithm": "sha256",
        "digest": "$SHA256"
      }
    }
  }
}
EOF

_prepare_consumer_env

if [[ "${SKIP_LINUX_DEPS:-0}" != "1" ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  fi
fi

cd "$ROOT"
"${FLUTTER[@]}" pub get
cd example
"${FLUTTER[@]}" build linux --debug

cd "$ROOT"
bash tool/ci/verify_native_assets.sh linux

echo "Prebuilt e2e OK (linux-x64)"
