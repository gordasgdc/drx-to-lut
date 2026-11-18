"""Compară decodorul propriu cu zstd din Python 3.14 (compression.zstd), pe date variate."""
import os, random, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from drx2lut import zstd as Z
try:
    from compression import zstd as REF
except ImportError:
    REF = None

def samples():
    r = random.Random(7)
    yield b""
    yield b"a"
    yield b"abc" * 5000
    yield bytes(r.randrange(256) for _ in range(5000))
    words = [b"alpha", b"beta", b"gamma", b"dev.gordas.style.v3.look.awg4-logc4.full", b"OfxImageEffectContextGeneral", b"\x00\x01\x02"]
    for n in (50, 700, 3000, 20000, 150000):
        yield b" ".join(r.choice(words) for _ in range(n // 6 + 1))[:n]
    yield bytes(r.choice(b"AAAABBC\x00\xff") for _ in range(60000))
    for f in ("/usr/share/dict/words", "/etc/hosts", "/usr/bin/true"):
        if os.path.exists(f): yield open(f, "rb").read()[:300000]

@unittest.skipIf(REF is None, "necesită Python 3.14 pentru referință")
class T(unittest.TestCase):
    def test_roundtrip(self):
        n = 0
        for s in samples():
            for lvl in (1, 3, 9, 15, 19):
                c = REF.compress(s, level=lvl); self.assertEqual(Z.decompress(c), s, (len(s), lvl)); n += 1
        self.assertGreater(n, 30)
    def test_invalid(self):
        with self.assertRaises(Z.ZstdError): Z.decompress(b"nope")
if __name__ == "__main__": unittest.main()
