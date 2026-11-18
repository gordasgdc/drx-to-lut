"""Generează rețeaua identitate 65³ ca EXR float necomprimat 1920×1080: pixelul k are (R,G,B) = (k%65, k//65%65, k//4225)/64; restul 0.
Ordinea (R cel mai rapid) este cea a fișierelor .cube."""
import os, struct
W, H, N = 1920, 1080, 65

def _attr(name, typ, val): return name.encode() + b"\0" + typ.encode() + b"\0" + struct.pack("<i", len(val)) + val

def build():
    g = [i / 64.0 for i in range(N)]
    rows_used = (N ** 3 + W - 1) // W
    header = b"v/1\x01\x02\x00\x00\x00"
    ch = b"".join(n.encode() + b"\0" + struct.pack("<iBBBBii", 2, 0, 0, 0, 0, 1, 1) for n in "BGR") + b"\0"
    header += _attr("channels", "chlist", ch) + _attr("compression", "compression", b"\x00")
    header += _attr("dataWindow", "box2i", struct.pack("<4i", 0, 0, W - 1, H - 1)) + _attr("displayWindow", "box2i", struct.pack("<4i", 0, 0, W - 1, H - 1))
    header += _attr("lineOrder", "lineOrder", b"\x00") + _attr("pixelAspectRatio", "float", struct.pack("<f", 1.0))
    header += _attr("screenWindowCenter", "v2f", struct.pack("<2f", 0, 0)) + _attr("screenWindowWidth", "float", struct.pack("<f", 1.0)) + b"\0"
    row_bytes = W * 4 * 3; chunk = 8 + row_bytes
    base = len(header) + 8 * H; out = bytearray(header)
    for y in range(H): out += struct.pack("<Q", base + y * chunk)
    zero = b"\0" * (W * 4)
    for y in range(H):
        out += struct.pack("<ii", y, row_bytes)
        if y < rows_used:
            r = []; gg = []; b = []
            for x in range(W):
                k = y * W + x
                if k < N ** 3: r.append(g[k % N]); gg.append(g[(k // N) % N]); b.append(g[k // (N * N)])
                else: r.append(0.0); gg.append(0.0); b.append(0.0)
            out += struct.pack("<%df" % W, *b) + struct.pack("<%df" % W, *gg) + struct.pack("<%df" % W, *r)
        else: out += zero * 3
    return bytes(out)

def ensure(path):
    # Rețeaua e reconstruită dacă lipsește sau e trunchiată (un EXR complet are zeci de MB).
    data = build()
    if not os.path.exists(path) or os.path.getsize(path) != len(data):
        tmp = path + ".tmp"
        with open(tmp, "wb") as fh: fh.write(data)
        os.replace(tmp, path)
    return path
