import json, sys, time

class UserError(Exception):
    """Eroare cu cod stabil; aplicația o localizează. Nu conține text pentru utilizator."""
    def __init__(self, code, **params):
        super().__init__(code); self.code = code; self.params = params

def emit(**kw):
    kw.setdefault("t", round(time.time(), 3))
    sys.stdout.write(json.dumps(kw, ensure_ascii=False) + "\n"); sys.stdout.flush()

def progress(pct, stage, **params):
    emit(type="progress", pct=int(pct), stage=stage, **params)
