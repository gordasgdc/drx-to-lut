import os, sys, tempfile, unittest, json, struct
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from drx2lut import drx, exrio, cube, lattice, classify, readme
from drx2lut.events import UserError

BODY_HEX = "8128b52ffd60f801ed0300c2871b1d508b1d9b8decf2749c245ca24cea1371dca12f6d3c748774584898350201c08ce2f38f4890415b1cb714bc1cd39486aba0c24e31bb30d56d1bb5b19b8dbd8ebf8821364c074fe80913727781e55b1c1c9d4804ee8c5606e5bb62b2f1f4f9775d93b23fa6a4d28bd14b9d382e24030053f20ae781ccad2bc10c"
SAMPLE = '<?xml version="1.0"?>\n<!--DbAppVer="21.2.0.0006" DbPrjVer="17"-->\n<Gallery::GyStill DbId="x"><Body>' + BODY_HEX + '</Body></Gallery::GyStill>'

class T(unittest.TestCase):
    def tmp(self, name, data, mode="w"):
        d = tempfile.mkdtemp(); p = os.path.join(d, name); open(p, mode).write(data); return p
    def test_drx_ok(self):
        i = drx.parse(self.tmp("a.drx", SAMPLE)); self.assertEqual(i["resolve_version"], "21.2.0.0006")
        self.assertEqual(i["ofx_ids"], ["dev.gordas.style.v3.look.awg4-logc4.full", "dev.gordas.style.v3.drt.awg4-logc4.full"]); self.assertEqual(i["ofx_instances"], 1)
    def test_drx_invalid(self):
        for name, data, reason in (("a.drx", "hello", "not_drx"), ("b.drx", "<Gallery::GyStill></Gallery::GyStill>", "no_grade"), ("c.drx", SAMPLE.replace(BODY_HEX, BODY_HEX[:60] + "ff" + BODY_HEX[62:]), "corrupt"), ("d.drx", "", "size")):
            with self.assertRaises(UserError) as c: drx.parse(self.tmp(name, data))
            self.assertEqual(c.exception.code, "drx_invalid", reason); self.assertEqual(c.exception.params["reason"], reason)
        with self.assertRaises(UserError) as c: drx.parse(self.tmp("e.drx", SAMPLE.replace(BODY_HEX, "00ff")))
        self.assertEqual(c.exception.code, "drx_unsupported")
        with self.assertRaises(UserError) as c: drx.parse("/nonexistent/x.drx")
        self.assertEqual(c.exception.code, "drx_unreadable")
    def test_lattice_roundtrip(self):
        p = os.path.join(tempfile.mkdtemp(), "l.exr"); lattice.ensure(p); self.assertEqual(os.path.getsize(p), len(lattice.build()))
        px = exrio.read_first_pixels(p, 65 ** 3)
        for k in (0, 1, 64, 65, 4225, 65 ** 3 - 1): self.assertEqual(px[k], ((k % 65) / 64, ((k // 65) % 65) / 64, (k // 4225) / 64))
        with open(p, "r+b") as f: f.seek(0); f.write(b"XXXX")
        with self.assertRaises(UserError): exrio.read_first_pixels(p, 10)
    def test_cube(self):
        p = os.path.join(tempfile.mkdtemp(), "c.cube"); rows = [(0.1, 0.2, 0.3)] * 65 ** 3; cube.write(p, rows, 'a"b', "c"); ok, lo, hi = cube.validate(p); self.assertTrue(ok); self.assertEqual((lo, hi), (0.1, 0.3))
        rows[5] = (float("nan"), 0, 0); cube.write(p, rows, "x", "c"); self.assertFalse(cube.validate(p)[0])
        with self.assertRaises(ValueError): cube.write(p, rows[:10], "x", "c")
    def test_classify(self):
        self.assertEqual(classify.node_class("03 — Optics", ["OFX: Optics"]), "spatial"); self.assertEqual(classify.node_class("", ["Noise Reduction"]), "spatial")
        self.assertEqual(classify.node_class("08 — Look", ["OFX: Look"]), "pixel"); self.assertEqual(classify.node_class("01 — Input Transform", ["OFX: Input Transform"]), "pixel")
        self.assertEqual(classify.node_class("", []), "native"); self.assertEqual(classify.node_class("x", ["OFX: Mystery Plugin"]), "unknown")
    def test_readme_langs(self):
        rows = [dict(index=1, label="A", tools=["OFX: Look"], enabled=True, included=True), dict(index=2, label="", tools=[], enabled=True, included=False, excluded_by_user=True), dict(index=3, label="Optics", tools=["OFX: Optics"], enabled=True, included=False, cls="spatial")]
        for l in ("ro", "en", "es"):
            t = readme.render(l, "n", rows, "1.0", {}, "21"); self.assertIn("Tetrahedral", t); self.assertIn("n_65.drx", t)
        self.assertNotIn("/Users/", t)
    def test_resolve_not_running(self):
        from drx2lut import resolve as RS, core
        orig = RS.running
        try:
            RS.running = lambda: False
            with self.assertRaises(UserError) as c: RS.connect()
            self.assertEqual(c.exception.code, "resolve_not_running")
        finally: RS.running = orig
    def test_resolve_library_missing(self):
        from drx2lut import resolve as RS
        orig_r, orig_e = RS.running, os.environ.get("RESOLVE_SCRIPT_LIB")
        try:
            RS.running = lambda: True; os.environ["RESOLVE_SCRIPT_LIB"] = "/nonexistent/fusionscript.so"
            with self.assertRaises(UserError) as c: RS.connect()
            self.assertIn(c.exception.code, ("resolve_not_installed", "scripting_unavailable"))
        finally:
            RS.running = orig_r
            if orig_e is None: os.environ.pop("RESOLVE_SCRIPT_LIB", None)
            else: os.environ["RESOLVE_SCRIPT_LIB"] = orig_e
if __name__ == "__main__": unittest.main()
