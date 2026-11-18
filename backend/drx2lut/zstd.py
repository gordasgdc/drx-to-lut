"""Decodor Zstandard minimal, doar bibliotecă standard (RFC 8878). Folosit pentru a citi identificatorii efectelor din DRX.
Citește un singur cadru; fără dicționare; nu verifică suma de control. Scris pentru intrări mici (zeci de KB)."""


class ZstdError(Exception):
    pass


_LL_BASE = list(range(16)) + [16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536]
_LL_BITS = [0] * 16 + [1, 1, 1, 1, 2, 2, 3, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
_ML_BASE = [c + 3 for c in range(32)] + [35, 37, 39, 41, 43, 47, 51, 59, 67, 83, 99, 131, 259, 515, 1027, 2051, 4099, 8195, 16387, 32771, 65539]
_ML_BITS = [0] * 32 + [1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
_LL_DEF = (6, [4, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 1, 1, 1, 1, 1, -1, -1, -1, -1])
_ML_DEF = (6, [1, 4, 3, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1])
_OF_DEF = (5, [1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1])


class _Fwd:
    """Flux de biți direct (little endian), pentru descrierile de tabele."""
    def __init__(self, data, pos=0):
        self.d = data; self.bit = pos * 8

    def peek(self, n):
        v = 0
        for i in range(n):
            b = self.bit + i; byte = b >> 3
            v |= (((self.d[byte] >> (b & 7)) & 1) if byte < len(self.d) else 0) << i
        return v

    def read(self, n):
        v = self.peek(n); self.bit += n; return v

    def bytes_used(self, start):
        return (self.bit + 7) // 8 - start


class _Back:
    """Flux de biți invers: ultimul octet are un bit-santinelă; se citește de la capăt spre început."""
    def __init__(self, data):
        if not data or data[-1] == 0: raise ZstdError("flux invers invalid")
        self.x = int.from_bytes(data, "little"); self.p = self.x.bit_length() - 1; self.over = False

    def read(self, n):
        if n == 0: return 0
        self.p -= n
        if self.p < 0:
            self.over = True; v = (self.x & ((1 << (n + self.p)) - 1)) << (-self.p) if n + self.p > 0 else 0; return v
        return (self.x >> self.p) & ((1 << n) - 1)

    def peek_pad(self, n):
        if self.p >= n: return (self.x >> (self.p - n)) & ((1 << n) - 1)
        if self.p <= 0: return 0
        return (self.x & ((1 << self.p) - 1)) << (n - self.p)


def _read_ncount(data, pos, max_sym, max_al):
    r = _Fwd(data, pos); al = r.read(4) + 5
    if al > max_al: raise ZstdError("accuracy log prea mare")
    remaining = (1 << al) + 1; threshold = 1 << al; nb = al + 1; probs = []; prev0 = False
    while remaining > 1 and len(probs) <= max_sym:
        if prev0:
            while True:
                rep = r.read(2); probs.extend([0] * rep)
                if rep != 3: break
            prev0 = False
            if remaining <= 1 or len(probs) > max_sym: break
        mx = (2 * threshold - 1) - remaining
        v = r.peek(nb)
        if (v & (threshold - 1)) < mx: count = v & (threshold - 1); r.bit += nb - 1
        else:
            count = v & (2 * threshold - 1)
            if count >= threshold: count -= mx
            r.bit += nb
        count -= 1; remaining -= abs(count); probs.append(count); prev0 = count == 0
        while remaining < threshold and threshold > 1: nb -= 1; threshold >>= 1
    if remaining != 1: raise ZstdError("distribuție FSE incorectă")
    return al, probs, r.bytes_used(pos)


def _build_fse(al, probs):
    size = 1 << al; table = [0] * size; high = size - 1; nxt = []
    for s, p in enumerate(probs):
        if p == -1: table[high] = s; high -= 1; nxt.append(1)
        else: nxt.append(p)
    step = (size >> 1) + (size >> 3) + 3; mask = size - 1; pos = 0
    for s, p in enumerate(probs):
        if p <= 0: continue
        for _ in range(p):
            table[pos] = s; pos = (pos + step) & mask
            while pos > high: pos = (pos + step) & mask
    dec = [None] * size
    for i in range(size):
        s = table[i]; x = nxt[s]; nxt[s] += 1; nb = al - (x.bit_length() - 1); dec[i] = (s, nb, (x << nb) - size)
    return al, dec


def _huff_from_weights(w):
    total = sum(1 << (x - 1) for x in w if x)
    if total == 0: raise ZstdError("pondere Huffman invalidă")
    mb = total.bit_length(); last = (1 << mb) - total
    if last & (last - 1): raise ZstdError("pondere Huffman invalidă")
    w = list(w) + [last.bit_length()]; mb = max(mb, 1)
    table = [None] * (1 << mb); pos = 0
    for wt in range(1, mb + 1):
        for s, x in enumerate(w):
            if x == wt:
                for _ in range(1 << (wt - 1)): table[pos] = (s, mb + 1 - wt); pos += 1
    if pos != (1 << mb): raise ZstdError("tabel Huffman incomplet")
    return mb, table


def _huff_stream(data, count, tab):
    mb, table = tab; br = _Back(data); out = bytearray()
    for _ in range(count):
        s, nb = table[br.peek_pad(mb)]; br.p -= nb
        out.append(s)
    return out


class _State:
    def __init__(self): self.huff = None; self.ll = None; self.of = None; self.ml = None; self.rep = [1, 4, 8]


def _literals(b, pos, st):
    b0 = b[pos]; t = b0 & 3; sf = (b0 >> 2) & 3
    if t in (0, 1):
        if sf in (0, 2): n = b0 >> 3; hl = 1
        elif sf == 1: n = (b0 >> 4) + (b[pos + 1] << 4); hl = 2
        else: n = (b0 >> 4) + (b[pos + 1] << 4) + (b[pos + 2] << 12); hl = 3
        pos += hl
        if t == 0: return bytes(b[pos:pos + n]), pos + n
        return bytes([b[pos]]) * n, pos + 1
    if sf == 0 or sf == 1:
        v = int.from_bytes(b[pos:pos + 3], "little"); n = (v >> 4) & 0x3FF; cs = (v >> 14) & 0x3FF; hl = 3; streams = 1 if sf == 0 else 4
    elif sf == 2:
        v = int.from_bytes(b[pos:pos + 4], "little"); n = (v >> 4) & 0x3FFF; cs = (v >> 18) & 0x3FFF; hl = 4; streams = 4
    else:
        v = int.from_bytes(b[pos:pos + 5], "little"); n = (v >> 4) & 0x3FFFF; cs = (v >> 22) & 0x3FFFF; hl = 5; streams = 4
    pos += hl; end = pos + cs; p = pos
    if t == 2:
        hb = b[p]; p += 1
        if hb >= 128:
            cnt = hb - 127; w = []
            for i in range(cnt):
                byte = b[p + i // 2]; w.append((byte >> 4) if i % 2 == 0 else (byte & 15))
            p += (cnt + 1) // 2
        else:
            al, probs, used = _read_ncount(b, p, 255, 6); al, dec = _build_fse(al, probs)
            br = _Back(bytes(b[p + used:p + hb])); s1 = br.read(al); s2 = br.read(al); w = []
            while True:
                sym, nb, base = dec[s1]; w.append(sym); s1 = base + br.read(nb)
                if br.over: w.append(dec[s2][0]); break
                sym, nb, base = dec[s2]; w.append(sym); s2 = base + br.read(nb)
                if br.over: w.append(dec[s1][0]); break
                if len(w) > 255: raise ZstdError("prea multe ponderi")
            p += hb
        st.huff = _huff_from_weights(w)
    elif st.huff is None: raise ZstdError("tabel Huffman lipsă")
    body = bytes(b[p:end])
    if streams == 1: lit = _huff_stream(body, n, st.huff)
    else:
        s1, s2, s3 = (int.from_bytes(body[i:i + 2], "little") for i in (0, 2, 4)); q = 6
        seg = [body[q:q + s1], body[q + s1:q + s1 + s2], body[q + s1 + s2:q + s1 + s2 + s3], body[q + s1 + s2 + s3:]]
        per = (n + 3) // 4; lit = bytearray()
        for i, sg in enumerate(seg): lit += _huff_stream(sg, per if i < 3 else n - 3 * per, st.huff)
    return bytes(lit), end


def _seq_table(mode, b, pos, default, attr, st, max_sym, max_al):
    if mode == 0: return _build_fse(*default), pos
    if mode == 1: return (0, [(b[pos], 0, 0)]), pos + 1
    if mode == 3:
        if getattr(st, attr) is None: raise ZstdError("tabel repetat lipsă")
        return getattr(st, attr), pos
    al, probs, used = _read_ncount(b, pos, max_sym, max_al); return _build_fse(al, probs), pos + used


def _block(b, st, out):
    lit, pos = _literals(b, 0, st)
    n0 = b[pos]; pos += 1
    if n0 == 0: out += lit; return
    if n0 < 128: nseq = n0
    elif n0 < 255: nseq = ((n0 - 128) << 8) + b[pos]; pos += 1
    else: nseq = b[pos] + (b[pos + 1] << 8) + 0x7F00; pos += 2
    modes = b[pos]; pos += 1
    st.ll, pos = _seq_table((modes >> 6) & 3, b, pos, _LL_DEF, "ll", st, 35, 9)
    st.of, pos = _seq_table((modes >> 4) & 3, b, pos, _OF_DEF, "of", st, 31, 8)
    st.ml, pos = _seq_table((modes >> 2) & 3, b, pos, _ML_DEF, "ml", st, 52, 9)
    br = _Back(bytes(b[pos:]))
    lls = br.read(st.ll[0]); ofs = br.read(st.of[0]); mls = br.read(st.ml[0]); lp = 0
    for i in range(nseq):
        ofc = st.of[1][ofs][0]; mlc = st.ml[1][mls][0]; llc = st.ll[1][lls][0]
        ov = (1 << ofc) + br.read(ofc); ml = _ML_BASE[mlc] + br.read(_ML_BITS[mlc]); ll = _LL_BASE[llc] + br.read(_LL_BITS[llc])
        if i < nseq - 1:
            s, nb, base = st.ll[1][lls]; lls = base + br.read(nb)
            s, nb, base = st.ml[1][mls]; mls = base + br.read(nb)
            s, nb, base = st.of[1][ofs]; ofs = base + br.read(nb)
        rep = st.rep
        if ov > 3: off = ov - 3; st.rep = [off, rep[0], rep[1]]
        else:
            idx = ov - 1 + (1 if ll == 0 else 0)
            if idx == 0: off = rep[0]
            elif idx == 1: off = rep[1]; st.rep = [rep[1], rep[0], rep[2]]
            elif idx == 2: off = rep[2]; st.rep = [rep[2], rep[0], rep[1]]
            else: off = rep[0] - 1; st.rep = [off, rep[0], rep[1]]
        out += lit[lp:lp + ll]; lp += ll
        if off <= 0 or off > len(out): raise ZstdError("decalaj invalid")
        s = len(out) - off
        if off >= ml: out += out[s:s + ml]
        else:
            for k in range(ml): out.append(out[s + k])
    out += lit[lp:]


def decompress(data, max_size=64 * 1024 * 1024):
    data = bytes(data)
    if data[:4] != b"\x28\xb5\x2f\xfd": raise ZstdError("nu e un cadru Zstandard")
    fd = data[4]; pos = 5; single = (fd >> 5) & 1; fcsf = fd >> 6; did = (0, 1, 2, 4)[fd & 3]
    if fd & 8: raise ZstdError("biți rezervați")
    if not single: pos += 1
    if did: raise ZstdError("dicționar neacceptat")
    pos += {0: 1 if single else 0, 1: 2, 2: 4, 3: 8}[fcsf]
    st = _State(); out = bytearray()
    while True:
        h = int.from_bytes(data[pos:pos + 3], "little"); pos += 3; last = h & 1; t = (h >> 1) & 3; sz = h >> 3
        if t == 0: out += data[pos:pos + sz]; pos += sz
        elif t == 1: out += bytes([data[pos]]) * sz; pos += 1
        elif t == 2: _block(data[pos:pos + sz], st, out); pos += sz
        else: raise ZstdError("tip de bloc rezervat")
        if len(out) > max_size: raise ZstdError("rezultat prea mare")
        if last: break
    return bytes(out)
