# Releasing

1. Bump the version everywhere in one commit: `macOS/DRXtoLUT/Resources/Info.plist`, `backend/drx2lut/core.py` (`VERSION`), `gdc-manifest.json`, `CHANGELOG.md`, `site/update.json`. `scripts/build_app.sh` refuses to build if they disagree.
2. `DRX2LUT_WORK=<external folder> scripts/build_app.sh --notarize` → `DRXtoLUT-<version>.pkg` (signed, notarized, stapled). The sha256 is computed after stapling.
3. `scripts/test.sh <pkg> <version>` (Swift checks) and `python3 backend/tests/test_backend.py`; `scripts/probe-update.sh <candidate-dir>` (update channel on 127.0.0.1).
4. Verify with a real Resolve (valid DRX, invalid DRX, missing effect, project switch, cancel, overwrite) using `DRXtoLUT --backend <command>` from the packaged app.
5. `scripts/capture-screens.sh`, `scripts/generate-guide.swift` (PDF guides RO/EN/ES) and `scripts/render-site.py <pkg> <date>`.
6. Publish in this order: tag + GitHub release (versioned pkg + stable-named copy) → site (`docs/drx-to-lut/` of the site repository) → `update.json`. Then check the live links and run the update-flow verifier.

## When GDC STYLE (or Resolve) changes
Nothing in this product is coupled to a GDC STYLE version. A new GDC STYLE plugin that is per-pixel but unknown to the classifier appears as "Unknown effect" (excluded by default). To recognise it, add its tool name to `KNOWN_PIXEL` in `backend/drx2lut/classify.py`, add a test, bump the PATCH version and release. A new Resolve version: re-run the verification in step 4 and update the compatibility statement on the site and in the app (About, Help) only for what was tested.
