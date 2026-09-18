#!/usr/bin/env bash
# Verifies Native Assets hook output after `flutter build` (M2-02).
# Usage: tool/ci/verify_native_assets.sh <android|ios|linux|macos|windows>
set -euo pipefail

PLATFORM="${1:-}"
BUILD_DIR="example/build"
ASSET_STEM="dart_sysinfo_native"

usage() {
  echo "Usage: $0 <android|ios|linux|macos|windows>" >&2
  exit 1
}

case "$PLATFORM" in
  android|ios|linux|macos|windows) ;;
  *) usage ;;
esac

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "ERROR: $BUILD_DIR not found. Run a Flutter build in example/ first." >&2
  exit 1
fi

# Restrict search roots so stale artifacts from other platform builds cannot pass.
case "$PLATFORM" in
  android)
    SEARCH_ROOTS=(
      "$BUILD_DIR/app"
      "$BUILD_DIR/native_assets/android"
    )
    ;;
  ios)
    SEARCH_ROOTS=(
      "$BUILD_DIR/ios"
      "$BUILD_DIR/native_assets/ios"
    )
    ;;
  linux)
    SEARCH_ROOTS=(
      "$BUILD_DIR/linux"
      "$BUILD_DIR/native_assets/linux"
    )
    ;;
  macos)
    SEARCH_ROOTS=(
      "$BUILD_DIR/macos"
      "$BUILD_DIR/native_assets/macos"
    )
    ;;
  windows)
    SEARCH_ROOTS=(
      "$BUILD_DIR/windows"
      "$BUILD_DIR/native_assets/windows"
    )
    ;;
esac

EXISTING_ROOTS=()
for root in "${SEARCH_ROOTS[@]}"; do
  if [[ -d "$root" ]]; then
    EXISTING_ROOTS+=("$root")
  fi
done

if [[ ${#EXISTING_ROOTS[@]} -eq 0 ]]; then
  echo "ERROR: no $PLATFORM build output under $BUILD_DIR" >&2
  exit 1
fi

MANIFESTS=()
for root in "${EXISTING_ROOTS[@]}"; do
  while IFS= read -r manifest; do
    MANIFESTS+=("$manifest")
  done < <(
    find "$root" \( -name 'native_assets.json' -o -name 'NativeAssetsManifest.json' \) -print 2>/dev/null | sort -u
  )
done

if [[ ${#MANIFESTS[@]} -eq 0 ]]; then
  echo "ERROR: no native_assets.json or NativeAssetsManifest.json under $PLATFORM build output" >&2
  exit 1
fi

echo "Found ${#MANIFESTS[@]} Native Assets manifest(s) for $PLATFORM."

MANIFEST_OK=false
for manifest in "${MANIFESTS[@]}"; do
  if grep -q "$ASSET_STEM" "$manifest"; then
    echo "Manifest references $ASSET_STEM: $manifest"
    MANIFEST_OK=true
  fi
done

ARTIFACTS=()
for root in "${EXISTING_ROOTS[@]}"; do
  while IFS= read -r artifact; do
    ARTIFACTS+=("$artifact")
  done < <(
    find "$root" -path '*/native_assets/*' \( \
      -name "${ASSET_STEM}.framework" -o \
      -name "${ASSET_STEM}.dll" -o \
      -name "${ASSET_STEM}.dylib" -o \
      -name "lib${ASSET_STEM}.so" \
    \) -print 2>/dev/null | sort -u
  )
done

if [[ ${#ARTIFACTS[@]} -gt 0 ]]; then
  echo "Native Assets artifacts under */native_assets/*:"
  for artifact in "${ARTIFACTS[@]}"; do
    echo "  $artifact"
  done
  exit 0
fi

MANIFEST_ARGS=()
for manifest in "${MANIFESTS[@]}"; do
  MANIFEST_ARGS+=("$manifest")
done

SEARCH_ARGS=()
for root in "${EXISTING_ROOTS[@]}"; do
  SEARCH_ARGS+=("$root")
done

RESOLVED=$(
  python3 - "$BUILD_DIR" "$ASSET_STEM" "${SEARCH_ARGS[@]}" -- "${MANIFEST_ARGS[@]}" <<'PY'
import json
import sys
from pathlib import Path

build_dir = Path(sys.argv[1])
asset_stem = sys.argv[2]
sep = sys.argv.index("--")
search_roots = [Path(p) for p in sys.argv[3:sep]]
manifests = [Path(p) for p in sys.argv[sep + 1:]]

def exists_asset(path: Path) -> bool:
    if path.is_file() and path.stat().st_size > 0:
        return True
    if path.suffix == ".framework" and path.is_dir():
        return any(path.rglob("*"))
    return path.is_dir() and any(path.iterdir())

found = []
for manifest in manifests:
    try:
        data = json.loads(manifest.read_text())
    except json.JSONDecodeError:
        continue
    assets = data.get("native-assets") or {}
    for _target, entries in assets.items():
        if not isinstance(entries, dict):
            continue
        for asset_id, path_entry in entries.items():
            if asset_stem not in asset_id and asset_stem not in str(path_entry):
                continue
            if not isinstance(path_entry, list) or len(path_entry) < 2:
                continue
            rel = Path(str(path_entry[1]))
            roots = [manifest.parent, *search_roots, build_dir]
            for root in roots:
                for candidate in (root / rel, root / rel.name):
                    if exists_asset(candidate):
                        found.append(str(candidate.resolve()))
                framework = root / f"{asset_stem}.framework"
                if exists_asset(framework):
                    found.append(str(framework.resolve()))

for line in sorted(set(found)):
    print(line)
PY
)

if [[ -n "$RESOLVED" ]]; then
  echo "Resolved Native Assets artifacts from manifest paths:"
  echo "$RESOLVED" | sed 's/^/  /'
  exit 0
fi

if [[ "$MANIFEST_OK" == true ]]; then
  echo "ERROR: manifest references $ASSET_STEM but no artifact found under */native_assets/*" >&2
  exit 1
fi

echo "ERROR: no $ASSET_STEM entry in Native Assets manifests and no artifact under */native_assets/*" >&2
echo "Manifests checked:" >&2
for manifest in "${MANIFESTS[@]}"; do
  echo "  $manifest" >&2
done
exit 1
