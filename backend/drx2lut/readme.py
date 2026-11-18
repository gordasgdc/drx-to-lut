"""Textul README scris lângă LUT, în limba aleasă (ro/en/es). Conținut: ce s-a inclus, intrare/ieșire, reproducere, aplicare, limite."""
T = {
"ro": dict(title="LUT creat cu DRX to LUT", tool="Instrument", cfg="Configurația (copie)", when="Data", resolve="Resolve", inc="INCLUS", exc_auto="EXCLUS automat (nu poate fi reprezentat într-un LUT)", exc_user="EXCLUS de utilizator", off="oprit în configurația salvată",
  nodes="NODURI", native="nod nativ (conținutul nu poate fi verificat)", io="INTRARE ȘI IEȘIRE", io_text="Intrare: valorile pixelilor exact așa cum intră în primul nod inclus; aplicația nu adaugă nicio conversie. Ieșire: ce iese din ultimul nod inclus. Aplică LUT-ul unde clipul are aceeași codare ca atunci când ai făcut configurația și NU repeta conversiile de intrare/ieșire deja incluse în noduri.",
  limits="LIMITE", lim1="LUT-ul reproduce doar operații per-pixel. Operațiile care depind de vecini sau de timp (blur, grăunte, halație, reducere de zgomot etc.) nu pot fi într-un LUT.", lim2="Aplicația nu detectează toate operațiile incompatibile: blur/reducere de zgomot/Mid-Detail native, măști, qualifiere și power windows nu sunt vizibile prin API.", lim3="Nu verifică setările de proiect din Resolve (gestiunea culorii, LUT-uri de proiect) și gradările din afara nodurilor din DRX.", lim4="Format .cube 65³, domeniu 0–1; aproximare: pot apărea diferențe lângă tranziții abrupte.",
  repro="REPRODUCERE", repro_text="Aplică fișierul .drx de lângă acest text pe un clip în Resolve (Gallery → clic dreapta pe still → Apply Grade) și compară cu LUT-ul.",
  apply="APLICARE", apply_text="Resolve → Project Settings → Color Management → Lookup Tables → Open LUT Folder: copiază .cube, apoi Update Lists. Pe un nod: clic dreapta → 3D LUT. Setează interpolarea 3D LUT la Tetrahedral."),
"en": dict(title="LUT created with DRX to LUT", tool="Tool", cfg="Configuration (copy)", when="Date", resolve="Resolve", inc="INCLUDED", exc_auto="EXCLUDED automatically (cannot be represented in a LUT)", exc_user="EXCLUDED by user", off="switched off in the saved configuration",
  nodes="NODES", native="native node (contents cannot be verified)", io="INPUT AND OUTPUT", io_text="Input: pixel values exactly as they enter the first included node; the app adds no conversion. Output: what leaves the last included node. Apply the LUT where the clip is in the same encoding as when you made the configuration, and do NOT repeat input/output conversions already included in the nodes.",
  limits="LIMITS", lim1="A LUT reproduces per-pixel operations only. Operations that depend on neighbours or time (blur, grain, halation, noise reduction, etc.) cannot be in a LUT.", lim2="The app does not detect every incompatible operation: native blur/noise reduction/Mid-Detail, masks, qualifiers and power windows are not visible through the API.", lim3="It does not check Resolve project settings (colour management, project LUTs) or grading outside the nodes stored in the DRX.", lim4=".cube 65³, domain 0–1; approximation: differences may appear near abrupt transitions.",
  repro="REPRODUCTION", repro_text="Apply the .drx file next to this text to a clip in Resolve (Gallery → right-click the still → Apply Grade) and compare with the LUT.",
  apply="APPLYING", apply_text="Resolve → Project Settings → Color Management → Lookup Tables → Open LUT Folder: copy the .cube, then Update Lists. On a node: right-click → 3D LUT. Set 3D LUT interpolation to Tetrahedral."),
"es": dict(title="LUT creado con DRX to LUT", tool="Herramienta", cfg="Configuración (copia)", when="Fecha", resolve="Resolve", inc="INCLUIDO", exc_auto="EXCLUIDO automáticamente (no puede representarse en un LUT)", exc_user="EXCLUIDO por el usuario", off="desactivado en la configuración guardada",
  nodes="NODOS", native="nodo nativo (su contenido no puede verificarse)", io="ENTRADA Y SALIDA", io_text="Entrada: valores de píxel tal como entran al primer nodo incluido; la aplicación no añade ninguna conversión. Salida: lo que sale del último nodo incluido. Aplica el LUT donde el clip tenga la misma codificación que cuando hiciste la configuración y NO repitas las conversiones de entrada/salida ya incluidas en los nodos.",
  limits="LÍMITES", lim1="Un LUT reproduce solo operaciones por píxel. Las operaciones que dependen de vecinos o del tiempo (desenfoque, grano, halación, reducción de ruido, etc.) no pueden estar en un LUT.", lim2="La aplicación no detecta todas las operaciones incompatibles: desenfoque/reducción de ruido/Mid-Detail nativos, máscaras, calificadores y power windows no son visibles a través de la API.", lim3="No comprueba los ajustes de proyecto de Resolve (gestión de color, LUT de proyecto) ni el etalonaje fuera de los nodos guardados en el DRX.", lim4=".cube 65³, dominio 0–1; aproximación: pueden aparecer diferencias cerca de transiciones abruptas.",
  repro="REPRODUCCIÓN", repro_text="Aplica el archivo .drx junto a este texto a un clip en Resolve (Gallery → clic derecho en el still → Apply Grade) y compáralo con el LUT.",
  apply="APLICACIÓN", apply_text="Resolve → Project Settings → Color Management → Lookup Tables → Open LUT Folder: copia el .cube y pulsa Update Lists. En un nodo: clic derecho → 3D LUT. Pon la interpolación de 3D LUT en Tetrahedral."),
}

def render(lang, name, rows, version, info, resolve_version):
    t = T.get(lang) or T["en"]; import time
    L = [t["title"], "=" * len(t["title"]), f'{t["tool"]}: DRX to LUT {version}', f'{t["cfg"]}: {name}_65.drx', f'{t["when"]}: {time.strftime("%Y-%m-%d %H:%M")}', f'{t["resolve"]}: {resolve_version}', "", t["io"], t["io_text"], "", t["nodes"]]
    for r in rows:
        if r["included"]: st = t["inc"]
        elif r.get("excluded_by_user"): st = t["exc_user"]
        elif not r["enabled"]: st = t["off"]
        else: st = t["exc_auto"]
        eff = ", ".join(r["tools"]) if r["tools"] else t["native"]
        L.append(f'  {r["index"]:2d}  {r["label"] or "-"}  [{eff}]  ->  {st}')
    L += ["", t["limits"]] + ["  - " + t[k] for k in ("lim1", "lim2", "lim3", "lim4")] + ["", t["repro"], t["repro_text"], "", t["apply"], t["apply_text"], ""]
    return "\n".join(L)
