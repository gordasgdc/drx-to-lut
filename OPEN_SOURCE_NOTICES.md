# Open-source notices — DRX to LUT

DRX to LUT itself is MIT-licensed (see `LICENSE`). The app bundle contains one third-party
component: a trimmed copy of the **CPython 3.12** interpreter and standard library, built by
[python-build-standalone](https://github.com/astral-sh/python-build-standalone) (Apple silicon).
Only the standard library is used; no pip packages are bundled.

| Component | Where | Licence |
|---|---|---|
| CPython 3.12 (interpreter + stdlib) | `Contents/Resources/python/` | Python Software Foundation License 2.0 — full text bundled as `Contents/Resources/python/lib/python3.12/LICENSE.txt` and below |
| python-build-standalone (build scripts) | build provenance only | MPL-2.0 (scripts, not shipped as code) |
| OpenSSL 3.5.x | statically linked in the interpreter | Apache-2.0 — https://www.openssl.org/source/license.html |
| SQLite | statically linked in the interpreter | Public domain — https://www.sqlite.org/copyright.html |
| expat | statically linked in the interpreter | MIT — https://github.com/libexpat/libexpat/blob/master/expat/COPYING |
| libffi | statically linked in the interpreter | MIT — https://github.com/libffi/libffi/blob/master/LICENSE |
| mpdecimal | statically linked in the interpreter | BSD-2-Clause — https://www.bytereef.org/mpdecimal/ |
| liblzma (xz) | statically linked in the interpreter | Public domain / 0BSD — https://tukaani.org/xz/ |
| bzip2 | statically linked in the interpreter | BSD-style — https://sourceware.org/bzip2/ |
| zlib | statically linked in the interpreter | zlib licence — https://zlib.net/zlib_license.html |

The list of statically linked libraries was derived from the symbols present in the interpreter
binary; the full licence text of each is published at the upstream address shown. The
backend's DRX decompression uses a pure-Python Zstandard decoder written for this project
(format specification: RFC 8878); it contains no third-party code.

## Not included

DaVinci Resolve is a product of Blackmagic Design and is **not** distributed with this app. GDC STYLE
Client, its plugins and its licences are **not** included either; the app works with an installation
the user already has. DRX to LUT is an independent project and is not affiliated with or endorsed
by Blackmagic Design.

## Python Software Foundation License (CPython)

See `Contents/Resources/python/lib/python3.12/LICENSE.txt` inside the app; the same text is
reproduced in `THIRD_PARTY/python-LICENSE.txt` in the source repository.
