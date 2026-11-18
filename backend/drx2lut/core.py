import os, sys, time, json, glob, shutil, hashlib
from . import drx as DRX, resolve as RS, lattice, exrio, cube, classify, readme
from .events import UserError, emit, progress

VERSION = "1.0.0"
N = 65 ** 3
TL = "DRX to LUT - run"

def _goto(tl, it):
    f = it.GetStart(); tl.SetCurrentTimecode("%02d:%02d:%02d:%02d" % (f // (24 * 3600), (f // (24 * 60)) % 60, (f // 24) % 60, f % 24)); time.sleep(0.7)
    for _ in range(20):
        c = tl.GetCurrentVideoItem()
        if c is not None and c.GetName() == it.GetName(): return
        time.sleep(0.5)
    raise UserError("playhead")

def _apply(tl, it, drx_path):
    for _ in range(6):
        _goto(tl, it); g = it.GetNodeGraph()
        if g.ApplyGradeFromDRX(drx_path, 0):
            for _ in range(20):
                time.sleep(0.5); g = it.GetNodeGraph(); n = g.GetNumNodes()
                if n and n > 1: return g
        tl.SetCurrentTimecode("01:00:00:00"); time.sleep(1.5)
    raise UserError("drx_rejected")

def _open(drx_path, allow_switch):
    """Validează DRX (fără Resolve), conectează, deschide proiectul de lucru, aplică DRX pe rețea. Returnează (resolve, project, timeline, item, graph, info)."""
    progress(3, "reading_drx"); info = DRX.parse(drx_path)
    progress(8, "connecting"); r = RS.connect()
    progress(12, "opening_project"); p = RS.open_work_project(r, allow_switch)
    mp = p.GetMediaPool(); rf = mp.GetRootFolder(); wd = RS.work_dir(); lat = lattice.ensure(os.path.join(wd, "lattice65.exr"))
    clips = {c.GetName(): c for c in rf.GetClipList()}
    if "lattice65.exr" not in clips:
        mp.ImportMedia([lat]); time.sleep(1); clips = {c.GetName(): c for c in rf.GetClipList()}
    if "lattice65.exr" not in clips: raise UserError("lattice_import_failed")
    progress(20, "building_timeline")
    for t in range(1, (p.GetTimelineCount() or 0) + 1):
        tl0 = p.GetTimelineByIndex(t)
        if tl0 and tl0.GetName() == TL: mp.DeleteTimelines([tl0]); break
    tl = mp.CreateEmptyTimeline(TL); p.SetCurrentTimeline(tl); r.OpenPage("color")
    mp.AppendToTimeline([{"mediaPoolItem": clips["lattice65.exr"]}]); time.sleep(1.5)
    its = tl.GetItemListInTrack("video", 1)
    if len(its) != 1: raise UserError("timeline_failed")
    it = its[0]; progress(32, "applying_drx"); g = _apply(tl, it, drx_path)
    return r, p, tl, it, g, info

def _describe(g):
    n = None
    for _ in range(20):
        n = g.GetNumNodes()
        if n: break
        g.GetToolsInNode(1); time.sleep(0.5)
    if not n: raise UserError("graph_unreadable")
    rows = []
    for k in range(1, n + 1):
        lab = g.GetNodeLabel(k) or ""; tools = list(g.GetToolsInNode(k) or []); en = bool(g.GetNodeEnabled(k))
        rows.append(dict(index=k, label=lab, tools=tools, enabled=en, cls=classify.node_class(lab, tools)))
    return rows

def _plist(path):
    import plistlib
    with open(path, "rb") as fh: return plistlib.load(fh)

def _ofx_bundles():
    out = []
    for base in ("/Library/OFX/Plugins", os.path.expanduser("~/Library/OFX/Plugins")): out += glob.glob(base + "/*.ofx.bundle")
    return out

def _bundle_ids():
    import plistlib
    ids = set()
    for b in _ofx_bundles():
        try: ids.add(_plist(b + "/Contents/Info.plist").get("CFBundleIdentifier", ""))
        except Exception: pass
    return ids

def _in_binaries(needle):
    nb = needle.encode()
    for b in _ofx_bundles():
        for f in glob.glob(b + "/Contents/*/*.ofx"):
            try:
                with open(f, "rb") as fh:
                    if nb in fh.read(): return True
            except OSError: pass
    return False

def _effect_check(info, rows):
    """Efectele OFX din DRX față de cele de pe acest Mac: (instanțe pe care Resolve nu le-a creat, ID-uri neregăsite în pluginurile instalate)."""
    api_ofx = sum(1 for r in rows for t in r["tools"] if t.lower().startswith("ofx"))
    missing_count = max(0, info["ofx_instances"] - api_ofx)
    ids = [i for i in info["ofx_ids"] if not i.startswith("com.blackmagicdesign")]; known = _bundle_ids() if ids else set()
    missing_ids = [i for i in ids if i not in known and not _in_binaries(i)]
    return missing_count, missing_ids

def inspect(drx_path, allow_switch=False):
    r, p, tl, it, g, info = _open(drx_path, allow_switch)
    rows = _describe(g); mc, mids = _effect_check(info, rows)
    emit(type="nodes", config=os.path.splitext(os.path.basename(drx_path))[0], nodes=rows, drx=info, missing_instances=mc, missing_ids=mids, resolve=r.GetVersionString(), version=VERSION)

def _render(r, p, tl, it, tag):
    wd = RS.work_dir(); d = os.path.join(wd, "render", tag); os.makedirs(d, exist_ok=True)
    for f in glob.glob(d + "/*.exr"): os.remove(f)
    p.SetCurrentRenderFormatAndCodec("exr", "RGBFloat"); p.DeleteAllRenderJobs()
    st = it.GetStart()
    p.SetRenderSettings({"SelectAllFrames": False, "MarkIn": st, "MarkOut": st, "TargetDir": d, "CustomName": tag + "_", "ExportVideo": True, "ExportAudio": False})
    job = p.AddRenderJob()
    if not job: raise UserError("render_failed")
    p.StartRendering()
    try:
        while p.IsRenderingInProgress():
            try: pc = int((p.GetRenderJobStatus(job) or {}).get("CompletionPercentage", 0))
            except Exception: pc = 0
            progress(55 + int(0.3 * pc), "rendering", pct_render=pc); time.sleep(0.6)
    except BaseException:
        try: p.StopRendering(); p.DeleteAllRenderJobs()
        except Exception: pass
        shutil.rmtree(d, ignore_errors=True); raise
    fs = sorted(glob.glob(d + "/*.exr"))
    if not fs: raise UserError("render_failed")
    return fs[0], d

def make(drx_path, outdir, name, exclude, overwrite, allow_switch, lang, io_confirmed):
    if not name or any(c in name for c in '/\\:\0') or name.startswith("."): raise UserError("bad_name")
    if not io_confirmed: raise UserError("io_not_confirmed")
    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, f"{name}_65.cube")
    if os.path.exists(out) and not overwrite: raise UserError("out_exists", path=out)
    r, p, tl, it, g, info = _open(drx_path, allow_switch)
    rows = _describe(g); mc, mids = _effect_check(info, rows)
    if mc or mids: raise UserError("effects_missing", count=mc, ids=mids)
    for row in rows:
        inc = row["enabled"] and row["cls"] != "spatial" and row["index"] not in exclude
        row["included"] = inc; row["excluded_by_user"] = row["index"] in exclude
        if row["enabled"] and not inc: g.SetNodeEnabled(row["index"], False)
    if not any(x["included"] for x in rows): raise UserError("nothing_included")
    time.sleep(1); progress(50, "rendering")
    exr, d = _render(r, p, tl, it, "lat")
    progress(88, "writing")
    try: px = exrio.read_first_pixels(exr, N)
    finally: shutil.rmtree(d, ignore_errors=True)
    if len(set(px)) < 16: raise UserError("render_constant")   # fișier media offline sau ieșire degenerată
    tmp = out + ".part"
    try:
        cube.write(tmp, px, name, f"DRX to LUT {VERSION}; see {name}_65.README.txt")
        ok, lo, hi = cube.validate(tmp)
        if not ok: raise UserError("cube_invalid")
        # companionii se scriu înainte de cub: un cub fără explicații nu apare
        shutil.copy(drx_path, os.path.join(outdir, f"{name}_65.drx"))
        with open(drx_path, "rb") as fh: sha = hashlib.sha256(fh.read()).hexdigest()
        meta = dict(tool="DRX to LUT", version=VERSION, resolve=r.GetVersionString(), drx_sha256=sha, drx_resolve_version=info["resolve_version"], size=65, nodes=rows, lut_range=[lo, hi])
        with open(os.path.join(outdir, f"{name}_65.lutinfo.json"), "w") as fh: json.dump(meta, fh, indent=1, ensure_ascii=False)
        with open(os.path.join(outdir, f"{name}_65.README.txt"), "w") as fh: fh.write(readme.render(lang, name, rows, VERSION, info, r.GetVersionString()))
        os.replace(tmp, out)
    except BaseException:
        if os.path.exists(tmp): os.remove(tmp)
        raise
    emit(type="done", cube=out, folder=outdir, included=[x["index"] for x in rows if x["included"]])

def check():
    if not RS.running(): emit(type="check", running=False); return
    r = RS.connect(); name, folder = RS.current(r); s = RS.read_session()
    emit(type="check", running=True, connected=True, project=name, work_project=RS.WORK_PROJECT, resolve=r.GetVersionString(), previous=s.get("previous_project"), version=VERSION)

def restore():
    r = RS.connect(); prev = RS.restore_previous(r); emit(type="restored", project=prev)
