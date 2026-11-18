"""Citește un fișier DRX (still exportat din Resolve) fără Resolve: validează structura și extrage efectele OFX referite."""
import binascii, re, os
from . import zstd
from .events import UserError

MAX_SIZE = 64 * 1024 * 1024
_ID = re.compile(rb"(?:dev|com|org|net|io)\.[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+")
_INST = re.compile(rb"OfxImageEffectContext[A-Za-z]*_[0-9a-fA-F-]{36}_\d+")

def parse(path):
    try:
        size = os.path.getsize(path)
        if size == 0 or size > MAX_SIZE: raise UserError("drx_invalid", reason="size")
        with open(path, "rb") as fh: raw = fh.read()
    except OSError as e:
        raise UserError("drx_unreadable", reason=e.strerror or "io")
    try: text = raw.decode("utf-8")
    except UnicodeDecodeError: raise UserError("drx_invalid", reason="encoding")
    if "<Gallery::GyStill" not in text: raise UserError("drx_invalid", reason="not_drx")
    m = re.search(r'DbAppVer="([0-9.]+)"', text)
    bodies = re.findall(r"<Body>([0-9a-fA-F\s]+)</Body>", text)
    if not bodies: raise UserError("drx_invalid", reason="no_grade")
    ids, insts = [], set(); decoded = 0
    for b in bodies:
        try: blob = binascii.unhexlify(re.sub(r"\s", "", b))
        except binascii.Error: raise UserError("drx_invalid", reason="corrupt")
        z = blob[1:] if blob[1:5] == b"\x28\xb5\x2f\xfd" else (blob if blob[:4] == b"\x28\xb5\x2f\xfd" else None)
        if z is None: continue
        try: d = zstd.decompress(z)
        except zstd.ZstdError: raise UserError("drx_invalid", reason="corrupt")
        decoded += 1
        for x in _ID.findall(d):
            s = x.decode()
            if s not in ids: ids.append(s)
        insts.update(_INST.findall(d))
    if decoded == 0: raise UserError("drx_unsupported", reason="body_format")
    return {"resolve_version": m.group(1) if m else None, "ofx_ids": ids, "ofx_instances": len(insts), "bodies": decoded}
