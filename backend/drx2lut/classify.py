"""Clasificarea nodurilor după NUMELE efectelor raportate de Resolve. NU este o analiză completă: Resolve nu expune blur/NR/măști/qualifiere nodurilor native."""
import re

# 1) Operații care NU pot fi reprezentate într-un LUT 3D (depind de vecini sau de timp), recunoscute după nume.
SPATIAL = re.compile(r"optic|film|blur|grain|halation|sharpen|noise|denois|glow|diffus|defocus|deflicker|flare|vignette|bokeh|mid.?detail|texture|lens|temporal", re.I)
# 2) Efecte recunoscute ca operații per-pixel (cunoscute din verificări): efectele de culoare GDC STYLE și instrumentele de culoare native.
KNOWN_PIXEL = {"input transform", "exposure + balance", "linear to log", "saturation + hue", "tone", "color", "look", "skin", "highlights + gamut", "drt",
               "primary balance", "saturation", "hue & lum mix", "saturation, hue & lum mix", "color space transform", "lut", "curves", "color wheels", "color warper", "hue vs hue", "hue vs sat", "lum vs sat"}

def tool_class(name):
    base = re.sub(r"^(ofx|resolvefx)\s*:\s*", "", name.strip(), flags=re.I).strip()
    if SPATIAL.search(base) and base.lower() not in KNOWN_PIXEL: return "spatial"
    if base.lower() in KNOWN_PIXEL: return "pixel"
    return "unknown"

def node_class(label, tools):
    """spatial: exclus automat (nu poate fi LUT). unknown: efect nerecunoscut, inclus cu avertisment. native: nod fără efecte identificabile; nu pot verifica ce conține. pixel: toate efectele recunoscute per-pixel (conținutul nativ rămâne neverificabil)."""
    classes = [tool_class(t) for t in tools]
    if label and SPATIAL.search(label) and not classes: return "spatial"
    if "spatial" in classes: return "spatial"
    if not classes: return "native"
    if "unknown" in classes: return "unknown"
    return "pixel"
