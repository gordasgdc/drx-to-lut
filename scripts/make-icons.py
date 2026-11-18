#!/usr/bin/env python3
"""Generează toate pictogramele din sursa aprobată (nemodificată): iconset + .icns macOS, favicon și iconițe web.
Doar redimensionare Lanczos; fără decupare, fără redesenare, canal alfa păstrat."""
import os, subprocess, sys, tempfile
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = f"{ROOT}/macOS/DRXtoLUT/Resources/branding/lut-app-icon-v1.png"
RES = f"{ROOT}/macOS/DRXtoLUT/Resources"; SITE = f"{ROOT}/site/assets"
im = Image.open(SRC).convert("RGBA")
def px(n):
    # reducere în trepte: o singură trecere de la 1254 la 16 produce alias
    out = im
    while out.width // 2 >= n and out.width > n * 2: out = out.resize((out.width // 2, out.height // 2), Image.LANCZOS)
    return out.resize((n, n), Image.LANCZOS)
iconset = tempfile.mkdtemp() + "/AppIcon.iconset"; os.makedirs(iconset)
for base in (16, 32, 128, 256, 512):
    px(base).save(f"{iconset}/icon_{base}x{base}.png"); px(base * 2).save(f"{iconset}/icon_{base}x{base}@2x.png")
subprocess.run(["iconutil", "-c", "icns", iconset, "-o", f"{RES}/AppIcon.icns"], check=True)
os.makedirs(SITE, exist_ok=True)
for n, name in ((16, "favicon-16.png"), (32, "favicon-32.png"), (48, "favicon-48.png"), (180, "apple-touch-icon.png"), (192, "icon-192.png"), (512, "icon-512.png")): px(n).save(f"{SITE}/{name}")
px(256).save(f"{SITE}/favicon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print("ok")
