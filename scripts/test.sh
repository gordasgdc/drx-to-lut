#!/bin/bash
# Verificări automate DRXtoLUT: redactare, rotație log, export, verificator de
# update, dezinstalare pe home izolat, logger defect. Ieșirea merge sub
# Totul generat merge în DRX2LUT_WORK (folder extern de lucru): nimic pe discul intern.
#   scripts/test.sh [pkg_valid] [versiune] [pkg_nesemnat]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT="${DRX2LUT_WORK:?definește DRX2LUT_WORK (folder de lucru pentru build/teste)}"
[ -d "$EXT" ] && [ -w "$EXT" ] || { echo "DRX2LUT_WORK indisponibil sau nescriibil"; exit 3; }
OUT="$EXT/builds/tests"; mkdir -p "$OUT/logs" "$OUT/clang" "$OUT/tmp"
SRC="$ROOT/macOS/DRXtoLUT/Sources/DRXtoLUT"
export CLANG_MODULE_CACHE_PATH="$OUT/clang" TMPDIR="$OUT/tmp/"
swiftc -O -o "$OUT/drx2lut-checks" -framework AppKit \
  "$ROOT/macOS/DRXtoLUT/Tests/DRXtoLUTChecks/main.swift" \
  "$SRC/DiagnosticLog.swift" "$SRC/Diagnostics.swift" "$SRC/UpdateVerifier.swift" \
  "$SRC/SelfUninstaller.swift" "$SRC/SelfUpdater.swift" "$SRC/AppMover.swift" "$SRC/Localization.swift"
rm -rf "$OUT/logs"; mkdir -p "$OUT/logs"
export DRX2LUT_LOG_DIR="$OUT/logs" DRX2LUT_LOG_MAX_BYTES=20000
[ $# -ge 2 ] && export DRX2LUT_TEST_PKG="$1" DRX2LUT_TEST_PKG_VERSION="$2"
[ $# -ge 3 ] && export DRX2LUT_TEST_PKG_UNSIGNED="$3"
STATUS=0
"$OUT/drx2lut-checks" | tee "$OUT/last-run.txt" || STATUS=$?
# Logger defect: calea de log nu poate fi creată; procesul trebuie să termine normal.
BROKEN=$(DRX2LUT_LOG_DIR=/dev/null/inexistent "$OUT/drx2lut-checks" --log-broken-child 2>&1 || true)
if echo "$BROKEN" | grep -q child-done; then echo "PASS  logger defect nu blochează operația"; else echo "FAIL  logger defect: $BROKEN"; STATUS=1; fi
exit $STATUS
