#!/usr/bin/env bash
# Add KnittStyler to the desktop application menu (current user, no root).
# Run again after moving the bundle folder; --remove takes the entry away.
set -euo pipefail

BUNDLE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ENTRY="$APPS/knittstyler.desktop"

if [ "${1:-}" = "--remove" ]; then
  rm -f "$ENTRY"
  update-desktop-database "$APPS" 2>/dev/null || true
  exit 0
fi

# The icon comes from the user's own KnittStyler.exe (needs icoutils: wrestool, icotool).
ICON="$BUNDLE/share/knittstyler.png"
EXE="$BUNDLE/app/KnittStyler/KnittStyler.exe"
if [ ! -f "$ICON" ] && [ -f "$EXE" ] && command -v wrestool >/dev/null && command -v icotool >/dev/null; then
  mkdir -p "$BUNDLE/share"
  wrestool -x -t 14 "$EXE" 2>/dev/null | icotool -x -i 2 -o "$ICON" - 2>/dev/null || rm -f "$ICON"
fi
ICON_LINE=""
[ -f "$ICON" ] && ICON_LINE="Icon=$ICON"

mkdir -p "$APPS"
cat > "$ENTRY" <<EOF
[Desktop Entry]
Type=Application
Name=KnittStyler
Comment=Knitting patterns for Silver Reed machines (Wine)
Comment[uk]=Візерунки для в'язальних машин Silver Reed (Wine)
Exec="$BUNDLE/knittstyler" %f
$ICON_LINE
Terminal=false
Categories=Graphics;
StartupWMClass=knittstyler.exe
EOF
chmod +x "$ENTRY"
update-desktop-database "$APPS" 2>/dev/null || true
echo "Menu entry created: $ENTRY"
