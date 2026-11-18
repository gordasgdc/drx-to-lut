#!/usr/bin/env python3
"""Randează site/index.html din site/index.src.html + update.json + pachetul publicat.
Versiunea, linkul, suma SHA-256, mărimea și data vin dintr-o singură sursă (update.json + pkg).
  scripts/render-site.py <pkg> <data ISO>"""
import json, os, sys, hashlib
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pkg, date = sys.argv[1], sys.argv[2]
u = json.load(open(f"{root}/site/update.json"))
v = u["version"]; url = u["download_url"]["mac"]
sha = hashlib.sha256(open(pkg, "rb").read()).hexdigest()
assert sha == u["sha256"]["mac"], "sha256 din update.json ≠ pachet"
size = os.path.getsize(pkg) / 1048576
s = open(f"{root}/site/index.src.html", encoding="utf-8").read()
for k, val in (("__VERSION__", v), ("__PKG_URL__", url), ("__SHA256__", sha), ("__SIZE__", f"{size:.1f} MB"), ("__DATE__", date)):
    s = s.replace(k, val)
assert "__" not in s.replace("__proto__", ""), "token nerezolvat"
open(f"{root}/site/index.html", "w", encoding="utf-8").write(s)
print("site/index.html", v, sha[:12], f"{size:.1f} MB")
