# Changelog — DRX to LUT (macOS)

## v1.0.0 (2026-11-18) — First public release

### Added
- Drop or choose a DaVinci Resolve DRX grade, see its nodes, confirm input and output, and create a 65³ `.cube` LUT.
- Node classification: goes into the LUT / cannot be in a LUT / unknown effect / unidentified Resolve operation, with honest warnings.
- Works in a separate Resolve project; never saves your project; asks before switching and can return to it.
- Progress, safe cancel, overwrite confirmation, atomic result (no incomplete LUT is ever left behind).
- A notes file, the DRX copy and a machine-readable info file next to each LUT.
- Romanian, English and Spanish interface, in-app Help and PDF guides.
- Update check with SHA-256, Developer ID and version verification; diagnostics export; complete uninstall.
