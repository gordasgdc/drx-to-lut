#!/bin/bash
# Pregătește runtime-ul Python redistribuibil (python-build-standalone 3.12,
# Apple silicon, PSF) tăiat la strictul necesar backend-ului (doar stdlib).
#   DRX2LUT_WORK=<folder extern> scripts/make-runtime.sh [calea/spre/cpython-3.12.x-macos-aarch64-none]
# Rezultat: $DRX2LUT_WORK/runtime/python/{bin,lib}
set -euo pipefail
WORK="${DRX2LUT_WORK:?definește DRX2LUT_WORK}"
[ -d "$WORK" ] && [ -w "$WORK" ] || { echo "DRX2LUT_WORK indisponibil"; exit 3; }
SRC="${1:-$(ls -d "$HOME"/.local/share/uv/python/cpython-3.12.*-macos-aarch64-none 2>/dev/null | tail -1)}"
[ -x "$SRC/bin/python3.12" ] || { echo "Nu găsesc cpython 3.12 aarch64 (python-build-standalone)"; exit 1; }
OUT="$WORK/runtime/python"; rm -rf "$OUT"; mkdir -p "$OUT/bin"
cp "$SRC/bin/python3.12" "$OUT/bin/python3.12"
ln -s python3.12 "$OUT/bin/python3"
ditto "$SRC/lib/python3.12" "$OUT/lib/python3.12"
P="$OUT/lib/python3.12"
rm -rf "$P/site-packages"/* "$P/test" "$P/idlelib" "$P/tkinter" "$P/turtledemo" "$P/turtle.py" "$P/ensurepip" "$P/lib2to3" \
       "$P/config-3.12-darwin" "$P/lib-dynload/_tkinter"* "$P/EXTERNALLY-MANAGED" "$P/pydoc_data" "$P/unittest/test"
find "$P" -name __pycache__ -type d -prune -exec rm -rf {} +
[ -f "$P/LICENSE.txt" ] || { echo "LICENSE.txt lipsește"; exit 1; }
# Binarul trebuie să depindă doar de biblioteci de sistem.
BAD=$(otool -L "$OUT/bin/python3.12" | tail -n +2 | awk '{print $1}' | grep -v '^/usr/lib/\|^/System/' || true)
[ -z "$BAD" ] || { echo "Dependențe non-sistem: $BAD"; exit 1; }
file "$OUT/bin/python3.12" | grep -q arm64 || { echo "nu e arm64"; exit 1; }
"$OUT/bin/python3" -E -s -B -c "import sys, json, hashlib, zlib, struct, plistlib, subprocess, signal, argparse; print(sys.version.split()[0], sys.prefix)"
du -sh "$OUT"
