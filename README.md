# DRX to LUT

**EN** — Turn a DaVinci Resolve grade (exported as a DRX file) into a 65³ `.cube` LUT on macOS. Drop the DRX, see which nodes can go into a LUT and which cannot, confirm the input and output, press “Create LUT 65”. Local, free, MIT-licensed. Interface and guides in Romanian, English and Spanish.

**RO** — Transformă un grading DaVinci Resolve (exportat ca DRX) într-un LUT `.cube` 65³ pe macOS. Tragi DRX-ul, vezi ce noduri pot intra într-un LUT și care nu, confirmi intrarea și ieșirea și apeși „Creează LUT 65”. Local, gratuit, licență MIT.

**ES** — Convierte una corrección de DaVinci Resolve (exportada como DRX) en un LUT `.cube` 65³ en macOS. Sueltas el DRX, ves qué nodos pueden ir en un LUT y cuáles no, confirmas la entrada y la salida y pulsas «Crear LUT 65». Local, gratis, licencia MIT.

- Site and download: https://gordas.dev/drx-to-lut/
- Requirements (verified): macOS 13+, Apple silicon; DaVinci Resolve Studio 21.2 running with external scripting enabled; the OFX effects used in the DRX installed on the same Mac (e.g. GDC STYLE Client, installed separately and **not** included).
- Limits: a LUT changes colour pixel by pixel; blur, grain, halation, noise reduction, masks and anything depending on neighbours or other frames cannot be in a LUT. Native Resolve operations cannot be fully identified. A 65³ LUT is an approximation. See the guide.
- Privacy: everything runs locally; the only network access is the update check.
- Docs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/RELEASING.md](docs/RELEASING.md), [CHANGELOG.md](CHANGELOG.md), [OPEN_SOURCE_NOTICES.md](OPEN_SOURCE_NOTICES.md).

DRX to LUT is an independent project and is not affiliated with or endorsed by Blackmagic Design. DaVinci Resolve is a trademark of Blackmagic Design Pty. Ltd.

## Build (maintainers)
```
DRX2LUT_WORK=<writable external folder> scripts/build_app.sh [--notarize]
```
Needs Xcode command-line tools, a Developer ID identity and a `notarytool` keychain profile. See [docs/RELEASING.md](docs/RELEASING.md).

## License
MIT — see [LICENSE](LICENSE). Third-party components: [OPEN_SOURCE_NOTICES.md](OPEN_SOURCE_NOTICES.md).
