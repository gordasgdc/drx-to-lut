#!/bin/bash
# Capturi reale ale aplicației (RO/EN/ES), din pachetul construit, prin `DRXtoLUT --snapshot`
# (fluxul real, cu Resolve pornit). Cere ca Resolve să fie deja în proiectul de lucru
# (altfel apare dialogul de schimbare a proiectului).
#   DRX2LUT_WORK=<folder extern> scripts/capture-screens.sh <drx valid> <drx corupt> <folder demo pentru LUT>
set -uo pipefail
EXT="${DRX2LUT_WORK:?definește DRX2LUT_WORK}"; GOOD="$1"; BAD="$2"; OUTD="$3"
V=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(dirname "$0")/../macOS/DRXtoLUT/Resources/Info.plist")
BIN="$EXT/builds/candidate-$V/DRX to LUT.app/Contents/MacOS/DRXtoLUT"; S="$EXT/evidence/screens"; mkdir -p "$S" "$EXT/builds/probe/logs"
export DRX2LUT_SKIP_APPMOVER=1 DRX2LUT_LOG_DIR="$EXT/builds/probe/logs"
shoot() { perl -e 'alarm 150; exec @ARGV' "$BIN" --snapshot "$@"; }
for lang in en ro es; do
  shoot "$S/idle-$lang-dark.png" $lang dark idle 760 700
  shoot "$S/review-$lang-dark.png" $lang dark review 760 960 "$GOOD" "$OUTD"
  shoot "$S/done-$lang-dark.png" $lang dark done 760 560 "$GOOD" "$OUTD"
  shoot "$S/failed-$lang-dark.png" $lang dark failed 760 560 "$BAD"
done
shoot "$S/review-en-light.png" en light review 760 960 "$GOOD" "$OUTD"
