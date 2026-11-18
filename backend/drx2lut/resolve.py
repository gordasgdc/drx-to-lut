"""Conectare la DaVinci Resolve (scripting extern) și gestionarea proiectului de lucru. Nu salvează și nu modifică proiectul utilizatorului."""
import os, sys, time, subprocess, json
from .events import UserError, emit

API = "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
LIB_DEFAULT = "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"
WORK_PROJECT = "DRX to LUT - work project"

def work_dir():
    d = os.environ.get("DRX2LUT_WORKDIR") or os.path.expanduser("~/Library/Application Support/DRX to LUT")
    os.makedirs(d, exist_ok=True); return d

def running():
    return subprocess.run(["pgrep", "-x", "Resolve"], capture_output=True).returncode == 0

def connect(tries=3):
    if not running(): raise UserError("resolve_not_running")
    os.environ.setdefault("RESOLVE_SCRIPT_API", API); os.environ.setdefault("RESOLVE_SCRIPT_LIB", LIB_DEFAULT)
    if not os.path.exists(os.environ["RESOLVE_SCRIPT_LIB"]): raise UserError("resolve_not_installed")
    mods = os.environ["RESOLVE_SCRIPT_API"] + "/Modules/"
    if not os.path.isdir(mods): raise UserError("scripting_unavailable")
    sys.path.append(mods)
    try: import DaVinciResolveScript as dvr
    except Exception: raise UserError("scripting_unavailable")
    for _ in range(tries):
        try: r = dvr.scriptapp("Resolve")
        except Exception: r = None
        if r: return r
        time.sleep(1.5)
    raise UserError("scripting_unavailable")

def current(r):
    """(nume proiect, nume folder) sau (None, None)."""
    pm = r.GetProjectManager(); p = pm.GetCurrentProject()
    try: folder = pm.GetCurrentFolder()
    except Exception: folder = None
    return (p.GetName() if p else None), folder

def _session_file(): return os.path.join(work_dir(), "session.json")

def read_session():
    try:
        with open(_session_file()) as fh: return json.load(fh)
    except Exception: return {}

def write_session(d):
    tmp = _session_file() + ".tmp"
    with open(tmp, "w") as fh: json.dump(d, fh)
    os.replace(tmp, _session_file())

SETTINGS = {"colorScienceMode": "davinciYRGB", "timelineResolutionWidth": "1920", "timelineResolutionHeight": "1080",
            "timelineOutputResolutionWidth": "1920", "timelineOutputResolutionHeight": "1080", "timelineFrameRate": "24", "videoDataLevels": "Full"}

def open_work_project(r, allow_switch):
    """Deschide (sau creează) proiectul de lucru. Proiectul utilizatorului nu e salvat de aplicație; schimbarea cere confirmare."""
    pm = r.GetProjectManager(); name, folder = current(r)
    if name == WORK_PROJECT: return pm.GetCurrentProject()
    if name is not None and not allow_switch: raise UserError("project_switch_required", project=name)
    if name is not None:
        write_session({"previous_project": name, "previous_folder": folder})
    pm.GotoRootFolder()
    if WORK_PROJECT in (pm.GetProjectListInCurrentFolder() or []): p = pm.LoadProject(WORK_PROJECT)
    else: p = pm.CreateProject(WORK_PROJECT)
    if not p: raise UserError("project_open_failed")
    for k, v in SETTINGS.items(): p.SetSetting(k, v)
    bad = [k for k, v in SETTINGS.items() if str(p.GetSetting(k)) not in (v, v + ".0")]
    if bad: raise UserError("project_setup_failed", settings=bad)
    return p

def restore_previous(r):
    """Reîncarcă proiectul deschis înaintea aplicației (din ultima stare salvată). Nu salvează nimic."""
    s = read_session(); prev = s.get("previous_project")
    if not prev: raise UserError("nothing_to_restore")
    pm = r.GetProjectManager(); name, _ = current(r)
    if name == prev: return prev
    pm.GotoRootFolder(); fo = s.get("previous_folder")
    if fo and fo not in (None, "", "Root"):
        try: pm.OpenFolder(fo)
        except Exception: pass
    if prev not in (pm.GetProjectListInCurrentFolder() or []): raise UserError("previous_not_found", project=prev)
    if not pm.LoadProject(prev): raise UserError("restore_failed", project=prev)
    write_session({}); return prev
