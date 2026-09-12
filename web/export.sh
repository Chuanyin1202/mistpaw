#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/web
godot --headless --path . --editor --import
godot --headless --path . --export-release Web build/web/index.html
cp web/mistpaw-logo.png web/mistpaw-og.png web/manifest.webmanifest build/web/
for file in build/web/index.wasm build/web/index.pck build/web/index.js; do
  gzip -9 -k -f "$file"
done
