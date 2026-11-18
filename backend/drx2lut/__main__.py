import sys, signal, argparse, traceback
from . import core
from .events import UserError, emit

def _term(*_): raise KeyboardInterrupt

def main(argv=None):
    ap = argparse.ArgumentParser(prog="drx2lut"); sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check"); sub.add_parser("restore")
    i = sub.add_parser("inspect"); i.add_argument("drx"); i.add_argument("--allow-switch", action="store_true")
    m = sub.add_parser("make"); m.add_argument("drx"); m.add_argument("outdir"); m.add_argument("name"); m.add_argument("--exclude", default=""); m.add_argument("--overwrite", action="store_true")
    m.add_argument("--allow-switch", action="store_true"); m.add_argument("--lang", default="en"); m.add_argument("--io-confirmed", action="store_true")
    a = ap.parse_args(argv)
    signal.signal(signal.SIGTERM, _term); signal.signal(signal.SIGINT, _term)
    try:
        if a.cmd == "check": core.check()
        elif a.cmd == "restore": core.restore()
        elif a.cmd == "inspect": core.inspect(a.drx, a.allow_switch); emit(type="done")
        else: core.make(a.drx, a.outdir, a.name, {int(x) for x in a.exclude.split(",") if x}, a.overwrite, a.allow_switch, a.lang, a.io_confirmed)
    except KeyboardInterrupt:
        emit(type="cancelled"); return 3
    except UserError as e:
        emit(type="error", code=e.code, **e.params); return 2
    except Exception as e:
        emit(type="error", code="internal", exc=type(e).__name__, detail=traceback.format_exc()[-1200:]); return 1
    return 0

if __name__ == "__main__": sys.exit(main())
