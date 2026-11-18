"""Citire minimală EXR scanline necomprimat (formatul pe care Resolve îl scrie pentru «RGBFloat», compresie 0)."""
import struct
from .events import UserError

def _attrs(f):
    if f.read(4) != b"v/1\x01": raise UserError("render_unreadable", reason="magic")
    if f.read(4)[0] != 2: raise UserError("render_unreadable", reason="version")
    a = {}
    while True:
        n = b""
        while True:
            c = f.read(1)
            if c == b"" : raise UserError("render_unreadable", reason="header")
            if c == b"\0": break
            n += c
        if not n: break
        t = b""
        while True:
            c = f.read(1)
            if c == b"\0": break
            t += c
        sz = struct.unpack("<i", f.read(4))[0]; a[n.decode()] = (t.decode(), f.read(sz))
    return a

def read_first_pixels(path, count):
    """Primele `count` pixeli RGB (ordinea scanline), ca listă de tupluri float."""
    with open(path, "rb") as f:
        a = _attrs(f)
        if a.get("compression", ("", b"\xff"))[1] != b"\x00": raise UserError("render_unreadable", reason="compression")
        x0, y0, x1, y1 = struct.unpack("<4i", a["dataWindow"][1]); w = x1 - x0 + 1; h = y1 - y0 + 1
        ch = []; d = a["channels"][1]; p = 0
        while d[p] != 0:
            e = d.index(b"\0", p); name = d[p:e].decode(); typ = struct.unpack("<i", d[e + 1:e + 5])[0]; ch.append((name, typ)); p = e + 1 + 16
        names = [n for n, _ in ch]
        for need in "RGB":
            if need not in names: raise UserError("render_unreadable", reason="channels")
        sizes = {0: 4, 1: 2, 2: 4}; fmts = {0: "<%dI", 1: "<%de", 2: "<%df"}
        rows = (count + w - 1) // w
        if rows > h: raise UserError("render_unreadable", reason="size")
        table_pos = f.tell(); f.seek(table_pos); offs = struct.unpack("<%dQ" % h, f.read(8 * h)); out = []
        for y in range(rows):
            f.seek(offs[y]); yy, ln = struct.unpack("<ii", f.read(8)); buf = f.read(ln); q = 0; planes = {}
            for name, typ in ch:
                n = w * sizes[typ]; seg = buf[q:q + n]; q += n
                if typ == 0: planes[name] = struct.unpack("<%dI" % w, seg)
                else: planes[name] = struct.unpack(fmts[typ] % w, seg)
            R, G, B = planes["R"], planes["G"], planes["B"]
            out.extend(zip(R, G, B))
        return out[:count]
