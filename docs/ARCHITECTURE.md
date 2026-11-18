# Architecture

```
macOS/DRXtoLUT/Sources/DRXtoLUT/   SwiftUI app (UI, localisation RO/EN/ES, update, diagnostics)
backend/drx2lut/                   Python (stdlib only): DRX parsing, Resolve scripting, lattice render, .cube writer
scripts/                           build, runtime trimming, icons, screenshots, guides, site rendering, tests
site/                              public page, update.json, catalog entry
```

**Flow.** The app starts the bundled interpreter (`Contents/Resources/python/bin/python3`) with the bundled backend and reads JSON lines from its stdout. The backend never emits prose: only stable codes and parameters (`progress`, `nodes`, `done`, `cancelled`, `error`); Swift localises them. Cancel = SIGTERM; the backend stops the render, cleans up and writes the `.cube` through a `.part` file renamed only after validation.

**Method.** A 65³ identity lattice (EXR, 1920×1080 float) is imported into a separate Resolve project, the DRX is applied to the clip, excluded nodes are disabled, the frame is rendered through the node graph and the first 65³ pixels become the cube rows. No colour maths is reimplemented: Resolve and the installed OFX effects do the work.

**Classification.** `classify.py`: `spatial` (blur, grain, halation, noise… by effect/label name), `pixel` (known per-pixel tools), `unknown` (unrecognised OFX), `native` (no identifiable tools; native blur, NR, masks and qualifiers are not detectable). It is name-based and says so.

**Project safety.** Work happens in "DRX to LUT - work project". Switching away from the user's project needs explicit confirmation; the previous project is recorded in `session.json` and `restore` reopens it. The user's project is never saved by the app.

**Runtime.** Trimmed python-build-standalone CPython 3.12 (arm64), signed with hardened runtime and `disable-library-validation` (it loads Resolve's `fusionscript.so`). No other entitlements.

**Updates.** `site/update.json` → `UpdateChecker` → `UpdateVerifier` (SHA-256 from the manifest, Developer ID Installer Team ID, bundle ID, version, app signature) → `SelfUpdater` (admin install, rollback). DRX to LUT and GDC STYLE are versioned independently.
