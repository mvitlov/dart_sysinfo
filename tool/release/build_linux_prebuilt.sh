#!/usr/bin/env bash
# Builds the linux-x64 prebuilt cdylib for M3-06.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NATIVE="$ROOT/packages/native"
OUT_DIR="${1:-$ROOT/dist/prebuilt/linux-x64}"
TARGET="x86_64-unknown-linux-gnu"
LIB_NAME="libdart_sysinfo_native.so"

mkdir -p "$OUT_DIR"

cd "$NATIVE"
rustup run stable cargo build --release \
  --manifest-path Cargo.toml \
  --target "$TARGET"

install -m 0644 \
  "$NATIVE/target/$TARGET/release/$LIB_NAME" \
  "$OUT_DIR/$LIB_NAME"

echo "Built $OUT_DIR/$LIB_NAME"
