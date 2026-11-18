import math, os
N = 65

def write(path_tmp, rows, title, comment):
    if len(rows) != N ** 3: raise ValueError("număr de rânduri")
    with open(path_tmp, "w") as f:
        f.write('TITLE "%s"\n# %s\nLUT_3D_SIZE %d\nDOMAIN_MIN 0 0 0\nDOMAIN_MAX 1 1 1\n' % (title.replace('"', "'"), comment, N))
        for r, g, b in rows: f.write("%.8f %.8f %.8f\n" % (r, g, b))

def validate(path):
    """Cub valid: 65³ rânduri, toate finite. Returnează (ok, min, max)."""
    n = 0; lo = float("inf"); hi = float("-inf")
    with open(path) as f:
        for line in f:
            if not line or line[0] in "#TDL": continue
            p = line.split()
            if len(p) != 3: return False, 0, 0
            for x in p:
                v = float(x)
                if not math.isfinite(v): return False, 0, 0
                lo = min(lo, v); hi = max(hi, v)
            n += 1
    return n == N ** 3, lo, hi
