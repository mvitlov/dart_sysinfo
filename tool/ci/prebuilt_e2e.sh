#!/usr/bin/env bash
# Self-contained prebuilt e2e for linux-x64 (M3-06).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIST="${PREBUILT_DIST:-$ROOT/dist/prebuilt/linux-x64}"
LIB="$DIST/libdart_sysinfo_native.so"
MANIFEST="$ROOT/.tmp/prebuilt-e2e-manifest.json"
REPO="${PREBUILT_REPOSITORY:-mvitlov/dart_sysinfo}"

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
  DART=(fvm dart)
else
  FLUTTER=(flutter)
  DART=(dart)
fi

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

export DART_SYSINFO_PREBUILT=1
export DART_SYSINFO_FROM_SOURCE=0
export DART_SYSINFO_PREBUILT_MANIFEST="$MANIFEST"
export DART_SYSINFO_SKIP_ATTESTATION=1
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

if [[ "${SKIP_LINUX_DEPS:-0}" != "1" ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  fi
fi

cd "$ROOT"
"${FLUTTER[@]}" pub get
cd example
"${FLUTTER[@]}" pub get
"${FLUTTER[@]}" build linux --debug

cd "$ROOT"
bash tool/ci/verify_native_assets.sh linux

echo "Prebuilt e2e OK (linux-x64)"
