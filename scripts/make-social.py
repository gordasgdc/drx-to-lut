#!/usr/bin/env python3
"""Imagine de previzualizare socială (1280×640) și copertă catalog (icon + nume), din sursa aprobată a pictogramei."""
import os
from PIL import Image, ImageDraw, ImageFont
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
icon = Image.open(f"{root}/macOS/DRXtoLUT/Resources/branding/lut-app-icon-v1.png").convert("RGBA")
def font(sz, bold=False):
    for p in ("/System/Library/Fonts/HelveticaNeue.ttc", "/System/Library/Fonts/Helvetica.ttc"):
        try: return ImageFont.truetype(p, sz, index=1 if bold else 0)
        except Exception: pass
    return ImageFont.load_default()
W, H = 1280, 640
im = Image.new("RGBA", (W, H), (238, 234, 229, 255)); d = ImageDraw.Draw(im)
ic = icon.resize((380, 380), Image.LANCZOS); im.alpha_composite(ic, (90, 130))
d.text((520, 190), "DRX to LUT", font=font(88, True), fill=(22, 23, 25, 255))
d.text((524, 306), "DaVinci Resolve grade to 65³ .cube LUT", font=font(34), fill=(101, 104, 107, 255))
d.text((524, 360), "macOS · Apple silicon · RO / EN / ES", font=font(26), fill=(168, 91, 35, 255))
d.text((524, 540), "gordas.dev/drx-to-lut", font=font(24), fill=(101, 104, 107, 255))
os.makedirs(f"{root}/site/assets", exist_ok=True)
im.convert("RGB").save(f"{root}/site/assets/social-preview.png", optimize=True)
print("ok")
