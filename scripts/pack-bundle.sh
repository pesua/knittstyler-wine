#!/usr/bin/env bash
# Pack the bundle for another machine: everything except the Wine prefix and local config.
# Usage: pack-bundle.sh [out.tar.gz]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist/knittstyler-$(date +%Y%m%d).tar.gz}"
mkdir -p "$(dirname "$OUT")"
tar -C "$ROOT" --transform 's,^bundle,knittstyler,' \
    --exclude=bundle/prefix --exclude=bundle/config/knittstyler.conf --exclude='*.part' \
    -czf "$OUT" bundle
echo "$OUT ($(du -h "$OUT" | cut -f1))"
