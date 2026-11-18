import Foundation
import Combine

/// Limbile pe care DRX to LUT le vorbește integral. Nu „principal română, restul
/// pe jumătate” — fiecare cheie există în toate trei, iar testul din
/// `LocalizationAudit` pică build-ul dacă una lipsește.
enum Lang: String, CaseIterable, Identifiable {
    case ro, en, es

    var id: String { rawValue }

    /// Numele limbii scris ÎN acea limbă. Un selector care zice
    /// „Spaniolă / Engleză / Română” în română e inutil exact pentru cine
    /// are nevoie de el.
    var nativeName: String {
        switch self {
        case .ro: return "Română"
        case .en: return "English"
        case .es: return "Español"
        }
    }

    var flagless: String {
        switch self {
        case .ro: return "RO"
        case .en: return "EN"
        case .es: return "ES"
        }
    }
}

/// Preferința utilizatorului: urmează sistemul, sau forțează o limbă.
///
/// Există din același motiv ca selectorul de temă (Regula 18): cineva poate
/// avea macOS în engleză și să vrea aplicația în română, sau invers. A urma
/// orbește sistemul nu e suficient.
enum LangPreference: Equatable, Hashable {
    case system
    case fixed(Lang)

    var storageValue: String {
        switch self {
        case .system: return "system"
        case .fixed(let lang): return lang.rawValue
        }
    }

    init(storageValue: String) {
        if let lang = Lang(rawValue: storageValue) {
            self = .fixed(lang)
        } else {
            self = .system
        }
    }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let key = "DRXtoLUT.language"

    @Published private(set) var preference: LangPreference
    @Published private(set) var current: Lang

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key) ?? "system"
        let preference = LangPreference(storageValue: stored)
        self.preference = preference
        self.current = Self.resolve(preference)
    }

    func set(_ preference: LangPreference) {
        UserDefaults.standard.set(preference.storageValue, forKey: Self.key)
        self.preference = preference
        self.current = Self.resolve(preference)
    }

    /// Limba sistemului, redusă la cele trei acoperite. Orice altceva
    /// primește ROMÂNĂ, nu engleză: e limba produsului și a autorului.
    private static func resolve(_ preference: LangPreference) -> Lang {
        switch preference {
        case .fixed(let lang):
            return lang
        case .system:
            let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "ro"
            return Lang(rawValue: String(code)) ?? .ro
        }
    }
}

// MARK: - Cheile

/// Fiecare text vizibil are o cheie aici. Un literal scris direct într-un
/// `Text(...)` nu e o scurtătură, e un bug: nu poate fi tradus și nu poate
/// fi găsit cu `grep` când cineva întreabă „unde scrie asta?”.

// MARK: - Cheile

enum K: String, CaseIterable {
    case appName, appTagline, dropTitle, dropSubtitle, chooseDRX, dropNotDRX
    case howTitle, how1, how2, how3, reqTitle, reqResolve
    case reqEffects, resolveOK, resolveOff, recheck, checking, inspecting
    case reviewTitle, reviewFile, nodeLabelEmpty, nodeDisabled, nodeIncludeA11y, clsPixel
    case clsSpatial, clsUnknown, clsNative, clsSpatialNote, clsUnknownNote, clsNativeNote
    case detectionNote, effectsMissingTitle, effectsMissingBody, effectsMissingIDs, ioTitle, ioBody
    case ioConfirm, outName, outFolder, chooseFolder, createLUT, createHintSelect
    case stageReadingDrx, stageConnecting, stageOpeningProject, stageBuildingTimeline, stageApplyingDrx, stageRendering
    case stageWriting, cancel, cancelling, cancelled, doneTitle, doneBody
    case doneNext, openFolder, anotherDRX, restoreProject, restoreProjectNamed, restored
    case switchTitle, switchBody, switchConfirm, overwriteTitle, overwriteBody, overwriteConfirm
    case errTitle, errResolveNotRunning, errResolveNotInstalled, errScripting, errProjectOpen, errProjectSetup
    case errNothingToRestore, errPreviousNotFound, errRestoreFailed, errDrxSize, errDrxEncoding, errDrxNotDrx
    case errDrxNoGrade, errDrxCorrupt, errDrxUnreadable, errDrxUnsupported, errDrxRejected, errBadName
    case errIoNotConfirmed, errNothingIncluded, errRenderFailed, errRenderConstant, errRenderUnreadable, errCubeInvalid
    case errLatticeImport, errTimeline, errGraph, errPlayhead, errInternal, errBackendMissing
    case errUnknownCode, help, helpTitle, helpExportT, helpExportB, helpUseT
    case helpUseB, helpApplyT, helpApplyB, helpLimitsT, helpLimitsB, helpReqT
    case helpReqB, helpPrivacyT, helpPrivacyB, about, aboutVersion, aboutCompat
    case aboutLicense, openSourceNotices, settings, general, appearance, language
    case theme, followSystem, themeSystem, themeLight, themeDark, checkForUpdates
    case quit, restoreMenu, updateAvailable, updateNow, updateLater, upToDate
    case updateFailed, appMoverTitle, appMoverMessage, appMoverMove, appMoverNotNow, appMoverFailedTitle
    case appMoverFailedMessage, appMoverVersionMismatch, appMoverStillTranslocated, appMoverAccessDenied, updateDownloading, updateVerifying
    case updateInstalling, updateWindowTitle, updateFailedTitle, updateManualHint, updateOpenPage, updateManifestInvalid
    case updateErrDownload, updateErrInstall, updateErrVersion, updateErrNoChecksum, updateErrBadURL, updateErrChecksum
    case updateErrUnsigned, updateErrSigner, updateErrPayload, updateErrApp, updateErrTool, diagnostics
    case openLogsFolder, copySessionID, exportDiagnostics, exportDone, exportFailed, debugTemporary
    case sessionID, uninstallSection, uninstallApp, uninstallConfirmTitle, uninstallConfirmBody, uninstallConfirmButton
    case uninstallFailedTitle, ok, notAvailable, unknown, loading, seconds
}


enum L {
    /// Traducerea cheii în limba activă.
    static func t(_ key: K) -> String {
        t(key, LocalizationManager.shared.current)
    }

    /// Varianta explicită — folosită de audit și de documentație, unde
    /// avem nevoie de toate trei deodată.
    static func t(_ key: K, _ lang: Lang) -> String {
        // Română ca ultimă plasă de siguranță: o cheie fără traducere nu
        // trebuie să producă niciodată un text gol pe ecran. Auditul o
        // prinde la build; utilizatorul nu trebuie s-o vadă niciodată.
        table[key]?[lang] ?? table[key]?[.ro] ?? key.rawValue
    }
    static let table: [K: [Lang: String]] = [
        .appName: [.ro: "DRX to LUT", .en: "DRX to LUT", .es: "DRX to LUT"],
        .appTagline: [.ro: "Creează un LUT 65³ din grading-ul tău DaVinci Resolve", .en: "Create a 65³ LUT from your DaVinci Resolve grade", .es: "Crea un LUT 65³ a partir de tu corrección en DaVinci Resolve"],
        .dropTitle: [.ro: "Trage aici fișierul DRX", .en: "Drop your DRX file here", .es: "Suelta aquí tu archivo DRX"],
        .dropSubtitle: [.ro: "sau alege-l din fereastră", .en: "or choose it from a dialog", .es: "o elígelo en un cuadro de diálogo"],
        .chooseDRX: [.ro: "Alege DRX…", .en: "Choose DRX…", .es: "Elegir DRX…"],
        .dropNotDRX: [.ro: "Fișierul nu are extensia .drx.", .en: "The file does not have a .drx extension.", .es: "El archivo no tiene la extensión .drx."],
        .howTitle: [.ro: "Cum funcționează", .en: "How it works", .es: "Cómo funciona"],
        .how1: [.ro: "1. În Resolve, pe pagina Color, clic dreapta pe un still din galerie și alege „Export…” (format DRX).", .en: "1. In Resolve, on the Color page, right-click a still in the gallery and choose “Export…” (DRX format).", .es: "1. En Resolve, en la página Color, haz clic derecho en un still de la galería y elige «Export…» (formato DRX)."],
        .how2: [.ro: "2. Trage DRX-ul aici. Vezi nodurile, ce intră în LUT și ce rămâne în afară.", .en: "2. Drop the DRX here. See the nodes, what goes into the LUT and what stays out.", .es: "2. Suelta el DRX aquí. Verás los nodos, qué entra en el LUT y qué queda fuera."],
        .how3: [.ro: "3. Confirmă intrarea și ieșirea, alege numele și apasă „Creează LUT 65”.", .en: "3. Confirm the input and output, choose the name and press “Create LUT 65”.", .es: "3. Confirma la entrada y la salida, elige el nombre y pulsa «Crear LUT 65»."],
        .reqTitle: [.ro: "Ai nevoie de", .en: "You need", .es: "Necesitas"],
        .reqResolve: [.ro: "DaVinci Resolve Studio pornit, cu scripting extern activat (Preferences ▸ System ▸ General ▸ External scripting using: Local).", .en: "DaVinci Resolve Studio running, with external scripting enabled (Preferences ▸ System ▸ General ▸ External scripting using: Local).", .es: "DaVinci Resolve Studio abierto, con scripting externo activado (Preferences ▸ System ▸ General ▸ External scripting using: Local)."],
        .reqEffects: [.ro: "Efectele OFX folosite în DRX, instalate pe acest Mac (de exemplu GDC STYLE Client, instalat separat).", .en: "The OFX effects used in the DRX, installed on this Mac (for example GDC STYLE Client, installed separately).", .es: "Los efectos OFX usados en el DRX, instalados en este Mac (por ejemplo GDC STYLE Client, instalado por separado)."],
        .resolveOK: [.ro: "Resolve %@ conectat", .en: "Resolve %@ connected", .es: "Resolve %@ conectado"],
        .resolveOff: [.ro: "Resolve nu răspunde", .en: "Resolve is not responding", .es: "Resolve no responde"],
        .recheck: [.ro: "Verifică din nou", .en: "Check again", .es: "Comprobar de nuevo"],
        .checking: [.ro: "Verific…", .en: "Checking…", .es: "Comprobando…"],
        .inspecting: [.ro: "Citesc DRX-ul în Resolve…", .en: "Reading the DRX in Resolve…", .es: "Leyendo el DRX en Resolve…"],
        .reviewTitle: [.ro: "Noduri din DRX", .en: "Nodes in the DRX", .es: "Nodos del DRX"],
        .reviewFile: [.ro: "Fișier: %@", .en: "File: %@", .es: "Archivo: %@"],
        .nodeLabelEmpty: [.ro: "(fără etichetă)", .en: "(no label)", .es: "(sin etiqueta)"],
        .nodeDisabled: [.ro: "dezactivat în DRX", .en: "disabled in the DRX", .es: "desactivado en el DRX"],
        .nodeIncludeA11y: [.ro: "Include nodul %d în LUT", .en: "Include node %d in the LUT", .es: "Incluir el nodo %d en el LUT"],
        .clsPixel: [.ro: "Intră în LUT", .en: "Goes into the LUT", .es: "Entra en el LUT"],
        .clsSpatial: [.ro: "Nu poate fi într-un LUT", .en: "Cannot be in a LUT", .es: "No puede estar en un LUT"],
        .clsUnknown: [.ro: "Efect necunoscut", .en: "Unknown effect", .es: "Efecto desconocido"],
        .clsNative: [.ro: "Operație Resolve neidentificată", .en: "Unidentified Resolve operation", .es: "Operación de Resolve no identificada"],
        .clsSpatialNote: [.ro: "Depinde de pixelii vecini sau de alte cadre (blur, grain, halation, zgomot…). Exclus automat.", .en: "Depends on neighbouring pixels or other frames (blur, grain, halation, noise…). Excluded automatically.", .es: "Depende de píxeles vecinos o de otros fotogramas (desenfoque, grano, halación, ruido…). Excluido automáticamente."],
        .clsUnknownNote: [.ro: "Instrumentul nu știe dacă lucrează pixel cu pixel. Exclus implicit; îl poți include pe răspunderea ta.", .en: "The tool cannot tell whether it works pixel by pixel. Excluded by default; you may include it at your own risk.", .es: "La herramienta no sabe si trabaja píxel a píxel. Excluido por defecto; puedes incluirlo bajo tu responsabilidad."],
        .clsNativeNote: [.ro: "Instrumentele native ale lui Resolve nu pot fi identificate complet: blur, reducerea zgomotului, măști sau qualifiers dintr-un astfel de nod NU sunt detectate și ar produce un LUT incorect.", .en: "Resolve's native tools cannot be fully identified: blur, noise reduction, masks or qualifiers inside such a node are NOT detected and would give a wrong LUT.", .es: "Las herramientas nativas de Resolve no pueden identificarse del todo: desenfoque, reducción de ruido, máscaras o qualifiers dentro de un nodo así NO se detectan y darían un LUT incorrecto."],
        .detectionNote: [.ro: "Detectarea se bazează pe numele efectelor vizibile în Resolve; nu este o analiză completă a imaginii.", .en: "Detection relies on effect names visible in Resolve; it is not a complete image analysis.", .es: "La detección se basa en los nombres de efectos visibles en Resolve; no es un análisis completo de la imagen."],
        .effectsMissingTitle: [.ro: "Efecte lipsă pe acest Mac", .en: "Effects missing on this Mac", .es: "Efectos que faltan en este Mac"],
        .effectsMissingBody: [.ro: "DRX-ul folosește efecte OFX pe care Resolve nu le-a putut încărca (%d instanțe). Instalează-le și deschide din nou DRX-ul; un LUT creat fără ele ar fi incomplet.", .en: "The DRX uses OFX effects that Resolve could not load (%d instances). Install them and open the DRX again; a LUT made without them would be incomplete.", .es: "El DRX usa efectos OFX que Resolve no pudo cargar (%d instancias). Instálalos y abre el DRX de nuevo; un LUT creado sin ellos estaría incompleto."],
        .effectsMissingIDs: [.ro: "ID-uri neregăsite: %@", .en: "IDs not found: %@", .es: "ID no encontrados: %@"],
        .ioTitle: [.ro: "Intrare și ieșire", .en: "Input and output", .es: "Entrada y salida"],
        .ioBody: [.ro: "LUT-ul conține exact nodurile bifate. Clipul trebuie să fie în același spațiu de culoare în care a fost făcut grading-ul din DRX (intrarea), iar rezultatul rămâne în spațiul în care ieșea ultimul nod inclus (ieșirea). Nu adăuga a doua oară transformările de intrare sau ieșire.", .en: "The LUT contains exactly the ticked nodes. The clip must be in the same colour space the DRX grade was made in (input), and the result stays in the space the last included node produced (output). Do not add input or output transforms a second time.", .es: "El LUT contiene exactamente los nodos marcados. El clip debe estar en el mismo espacio de color en que se hizo la corrección del DRX (entrada) y el resultado queda en el espacio que producía el último nodo incluido (salida). No añadas por segunda vez las transformaciones de entrada o salida."],
        .ioConfirm: [.ro: "Confirm intrarea și ieșirea de mai sus", .en: "I confirm the input and output above", .es: "Confirmo la entrada y la salida indicadas"],
        .outName: [.ro: "Nume LUT", .en: "LUT name", .es: "Nombre del LUT"],
        .outFolder: [.ro: "Destinație", .en: "Destination", .es: "Destino"],
        .chooseFolder: [.ro: "Alege folderul…", .en: "Choose folder…", .es: "Elegir carpeta…"],
        .createLUT: [.ro: "Creează LUT 65", .en: "Create LUT 65", .es: "Crear LUT 65"],
        .createHintSelect: [.ro: "Bifează cel puțin un nod și confirmă intrarea și ieșirea.", .en: "Tick at least one node and confirm the input and output.", .es: "Marca al menos un nodo y confirma la entrada y la salida."],
        .stageReadingDrx: [.ro: "Citesc DRX-ul", .en: "Reading the DRX", .es: "Leyendo el DRX"],
        .stageConnecting: [.ro: "Mă conectez la Resolve", .en: "Connecting to Resolve", .es: "Conectando con Resolve"],
        .stageOpeningProject: [.ro: "Pregătesc proiectul de lucru", .en: "Preparing the work project", .es: "Preparando el proyecto de trabajo"],
        .stageBuildingTimeline: [.ro: "Construiesc timeline-ul", .en: "Building the timeline", .es: "Creando la línea de tiempo"],
        .stageApplyingDrx: [.ro: "Aplic DRX-ul", .en: "Applying the DRX", .es: "Aplicando el DRX"],
        .stageRendering: [.ro: "Randez rețeaua 65³ prin noduri", .en: "Rendering the 65³ lattice through the nodes", .es: "Renderizando la malla 65³ por los nodos"],
        .stageWriting: [.ro: "Scriu și validez fișierul .cube", .en: "Writing and validating the .cube file", .es: "Escribiendo y validando el archivo .cube"],
        .cancel: [.ro: "Anulează", .en: "Cancel", .es: "Cancelar"],
        .cancelling: [.ro: "Opresc în siguranță…", .en: "Stopping safely…", .es: "Deteniendo con seguridad…"],
        .cancelled: [.ro: "Anulat. Nu a rămas niciun fișier LUT incomplet.", .en: "Cancelled. No incomplete LUT file was left behind.", .es: "Cancelado. No quedó ningún archivo LUT incompleto."],
        .doneTitle: [.ro: "LUT creat", .en: "LUT created", .es: "LUT creado"],
        .doneBody: [.ro: "Fișierul și explicațiile de utilizare sunt în folderul ales.", .en: "The file and the usage notes are in the chosen folder.", .es: "El archivo y las notas de uso están en la carpeta elegida."],
        .doneNext: [.ro: "Cum îl aplici: pune-l pe un nod al clipului aflat în spațiul de intrare confirmat, cu interpolare Tetrahedral, fără alte transformări de intrare sau ieșire.", .en: "How to apply it: put it on a node of a clip in the confirmed input space, with Tetrahedral interpolation and no further input or output transforms.", .es: "Cómo aplicarlo: ponlo en un nodo de un clip en el espacio de entrada confirmado, con interpolación Tetrahedral y sin más transformaciones de entrada o salida."],
        .openFolder: [.ro: "Deschide folderul", .en: "Open folder", .es: "Abrir carpeta"],
        .anotherDRX: [.ro: "Alt DRX", .en: "Another DRX", .es: "Otro DRX"],
        .restoreProject: [.ro: "Revino la proiectul tău", .en: "Return to your project", .es: "Volver a tu proyecto"],
        .restoreProjectNamed: [.ro: "Revino la „%@”", .en: "Return to “%@”", .es: "Volver a «%@»"],
        .restored: [.ro: "Proiectul „%@” a fost redeschis în Resolve.", .en: "Project “%@” was reopened in Resolve.", .es: "El proyecto «%@» se reabrió en Resolve."],
        .switchTitle: [.ro: "Schimb proiectul din Resolve?", .en: "Switch the project in Resolve?", .es: "¿Cambiar el proyecto en Resolve?"],
        .switchBody: [.ro: "Lucrez într-un proiect separat. Resolve este acum în „%@”. Salvează-ți munca înainte: proiectul tău nu este salvat automat, iar schimbarea îl închide. La final poți reveni la el.", .en: "I work in a separate project. Resolve is currently in “%@”. Save your work first: your project is not saved automatically and switching closes it. You can return to it afterwards.", .es: "Trabajo en un proyecto aparte. Resolve está ahora en «%@». Guarda tu trabajo antes: tu proyecto no se guarda automáticamente y el cambio lo cierra. Al final puedes volver a él."],
        .switchConfirm: [.ro: "Schimbă proiectul", .en: "Switch project", .es: "Cambiar proyecto"],
        .overwriteTitle: [.ro: "Fișierul există deja", .en: "The file already exists", .es: "El archivo ya existe"],
        .overwriteBody: [.ro: "„%@” există în folderul ales. Îl înlocuiesc?", .en: "“%@” already exists in the chosen folder. Replace it?", .es: "«%@» ya existe en la carpeta elegida. ¿Lo reemplazo?"],
        .overwriteConfirm: [.ro: "Înlocuiește", .en: "Replace", .es: "Reemplazar"],
        .errTitle: [.ro: "Nu am putut continua", .en: "We could not continue", .es: "No pudimos continuar"],
        .errResolveNotRunning: [.ro: "DaVinci Resolve nu este pornit. Pornește Resolve Studio și încearcă din nou.", .en: "DaVinci Resolve is not running. Start Resolve Studio and try again.", .es: "DaVinci Resolve no está abierto. Abre Resolve Studio e inténtalo de nuevo."],
        .errResolveNotInstalled: [.ro: "Nu găsesc instalarea DaVinci Resolve (biblioteca de scripting lipsește).", .en: "I cannot find a DaVinci Resolve installation (the scripting library is missing).", .es: "No encuentro una instalación de DaVinci Resolve (falta la biblioteca de scripting)."],
        .errScripting: [.ro: "Resolve nu acceptă conexiunea. Activează Preferences ▸ System ▸ General ▸ External scripting using ▸ Local și încearcă din nou. Scripting-ul extern cere ediția Studio.", .en: "Resolve does not accept the connection. Enable Preferences ▸ System ▸ General ▸ External scripting using ▸ Local and try again. External scripting requires the Studio edition.", .es: "Resolve no acepta la conexión. Activa Preferences ▸ System ▸ General ▸ External scripting using ▸ Local e inténtalo de nuevo. El scripting externo requiere la edición Studio."],
        .errProjectOpen: [.ro: "Nu am putut deschide proiectul de lucru în Resolve.", .en: "I could not open the work project in Resolve.", .es: "No pude abrir el proyecto de trabajo en Resolve."],
        .errProjectSetup: [.ro: "Proiectul de lucru nu a primit setările necesare. Încearcă din nou.", .en: "The work project did not accept the required settings. Try again.", .es: "El proyecto de trabajo no aceptó los ajustes necesarios. Inténtalo de nuevo."],
        .errNothingToRestore: [.ro: "Nu există un proiect anterior de redeschis.", .en: "There is no previous project to reopen.", .es: "No hay un proyecto anterior que reabrir."],
        .errPreviousNotFound: [.ro: "Proiectul anterior „%@” nu mai este în folderul curent al bazei de date. Deschide-l manual în Resolve.", .en: "The previous project “%@” is no longer in the current database folder. Open it manually in Resolve.", .es: "El proyecto anterior «%@» ya no está en la carpeta actual de la base de datos. Ábrelo manualmente en Resolve."],
        .errRestoreFailed: [.ro: "Resolve nu a putut redeschide proiectul „%@”. Deschide-l manual.", .en: "Resolve could not reopen project “%@”. Open it manually.", .es: "Resolve no pudo reabrir el proyecto «%@». Ábrelo manualmente."],
        .errDrxSize: [.ro: "Fișierul DRX este gol sau prea mare.", .en: "The DRX file is empty or too large.", .es: "El archivo DRX está vacío o es demasiado grande."],
        .errDrxEncoding: [.ro: "Fișierul nu poate fi citit ca text DRX.", .en: "The file cannot be read as DRX text.", .es: "El archivo no se puede leer como texto DRX."],
        .errDrxNotDrx: [.ro: "Fișierul nu este un DRX exportat din DaVinci Resolve.", .en: "The file is not a DRX exported from DaVinci Resolve.", .es: "El archivo no es un DRX exportado de DaVinci Resolve."],
        .errDrxNoGrade: [.ro: "DRX-ul nu conține niciun grading (nu are date de noduri). Exportă un still care are grading aplicat.", .en: "The DRX contains no grade (no node data). Export a still that has a grade applied.", .es: "El DRX no contiene ninguna corrección (sin datos de nodos). Exporta un still que tenga una corrección aplicada."],
        .errDrxCorrupt: [.ro: "Fișierul DRX pare corupt sau trunchiat. Exportă-l din nou din Resolve.", .en: "The DRX file looks corrupt or truncated. Export it again from Resolve.", .es: "El archivo DRX parece dañado o truncado. Expórtalo de nuevo desde Resolve."],
        .errDrxUnreadable: [.ro: "Nu pot citi fișierul DRX (lipsește sau nu am acces).", .en: "I cannot read the DRX file (missing or no access).", .es: "No puedo leer el archivo DRX (falta o no tengo acceso)."],
        .errDrxUnsupported: [.ro: "Acest DRX are un format pe care instrumentul nu îl recunoaște încă.", .en: "This DRX has a format the tool does not recognise yet.", .es: "Este DRX tiene un formato que la herramienta aún no reconoce."],
        .errDrxRejected: [.ro: "Resolve a refuzat să aplice DRX-ul. Verifică dacă a fost exportat dintr-o versiune compatibilă.", .en: "Resolve refused to apply the DRX. Check that it was exported from a compatible version.", .es: "Resolve se negó a aplicar el DRX. Comprueba que se exportó desde una versión compatible."],
        .errBadName: [.ro: "Numele nu este valid (fără / \\ : și fără punct la început).", .en: "The name is not valid (no / \\ : and no leading dot).", .es: "El nombre no es válido (sin / \\ : y sin punto inicial)."],
        .errIoNotConfirmed: [.ro: "Confirmă mai întâi intrarea și ieșirea.", .en: "Confirm the input and output first.", .es: "Confirma primero la entrada y la salida."],
        .errNothingIncluded: [.ro: "Niciun nod nu este inclus în LUT.", .en: "No node is included in the LUT.", .es: "Ningún nodo está incluido en el LUT."],
        .errRenderFailed: [.ro: "Randarea în Resolve a eșuat. Verifică spațiul pe disc și media din proiectul de lucru.", .en: "The render in Resolve failed. Check disk space and the work project media.", .es: "El render en Resolve falló. Comprueba el espacio en disco y los medios del proyecto de trabajo."],
        .errRenderConstant: [.ro: "Rezultatul randării este degenerat (o singură culoare). Cauze probabile: media offline sau un nod care distruge imaginea. Nu am scris niciun LUT.", .en: "The render result is degenerate (a single colour). Likely causes: offline media or a node that destroys the image. No LUT was written.", .es: "El resultado del render es degenerado (un solo color). Causas probables: medios sin conexión o un nodo que destruye la imagen. No se escribió ningún LUT."],
        .errRenderUnreadable: [.ro: "Nu pot citi imaginea randată de Resolve.", .en: "I cannot read the image rendered by Resolve.", .es: "No puedo leer la imagen renderizada por Resolve."],
        .errCubeInvalid: [.ro: "Fișierul .cube generat nu a trecut validarea și nu a fost păstrat.", .en: "The generated .cube file failed validation and was not kept.", .es: "El archivo .cube generado no superó la validación y no se conservó."],
        .errLatticeImport: [.ro: "Resolve nu a importat imaginea-rețea necesară.", .en: "Resolve did not import the lattice image it needs.", .es: "Resolve no importó la imagen de malla necesaria."],
        .errTimeline: [.ro: "Nu am putut construi timeline-ul de lucru în Resolve.", .en: "I could not build the work timeline in Resolve.", .es: "No pude crear la línea de tiempo de trabajo en Resolve."],
        .errGraph: [.ro: "Nu pot citi nodurile după aplicarea DRX-ului.", .en: "I cannot read the nodes after applying the DRX.", .es: "No puedo leer los nodos tras aplicar el DRX."],
        .errPlayhead: [.ro: "Resolve nu a poziționat cadrul curent. Încearcă din nou.", .en: "Resolve did not position the playhead. Try again.", .es: "Resolve no posicionó el cabezal. Inténtalo de nuevo."],
        .errInternal: [.ro: "Eroare internă neașteptată. Exportă diagnosticul din Setări și încearcă din nou.", .en: "Unexpected internal error. Export the diagnostics from Settings and try again.", .es: "Error interno inesperado. Exporta el diagnóstico desde Ajustes e inténtalo de nuevo."],
        .errBackendMissing: [.ro: "Componenta internă lipsește sau nu pornește. Reinstalează aplicația.", .en: "The internal component is missing or does not start. Reinstall the app.", .es: "Falta el componente interno o no arranca. Reinstala la aplicación."],
        .errUnknownCode: [.ro: "Eroare neprevăzută (%@).", .en: "Unexpected error (%@).", .es: "Error inesperado (%@)."],
        .help: [.ro: "Ajutor", .en: "Help", .es: "Ayuda"],
        .helpTitle: [.ro: "Ajutor — DRX to LUT", .en: "Help — DRX to LUT", .es: "Ayuda — DRX to LUT"],
        .helpExportT: [.ro: "Exportă DRX din Resolve", .en: "Export a DRX from Resolve", .es: "Exportar un DRX desde Resolve"],
        .helpExportB: [.ro: "Pe pagina Color aplică grading-ul pe un clip. Salvează un still (clic dreapta pe viewer ▸ Grab Still), apoi în galerie clic dreapta pe still ▸ Export…, alege formatul DRX și un nume.", .en: "On the Color page, grade a clip. Grab a still (right-click the viewer ▸ Grab Still), then in the gallery right-click the still ▸ Export…, choose the DRX format and a name.", .es: "En la página Color, corrige un clip. Captura un still (clic derecho en el visor ▸ Grab Still) y en la galería haz clic derecho en el still ▸ Export…, elige el formato DRX y un nombre."],
        .helpUseT: [.ro: "Creează LUT-ul", .en: "Create the LUT", .es: "Crear el LUT"],
        .helpUseB: [.ro: "Trage DRX-ul în fereastră sau alege-l. Aplicația lucrează într-un proiect separat din Resolve, nu în al tău. Verifici nodurile, confirmi intrarea și ieșirea, alegi numele și folderul și apeși „Creează LUT 65”. Rezultatul este un .cube 65³ plus un fișier cu explicații.", .en: "Drop the DRX into the window or choose it. The app works in a separate Resolve project, not yours. Review the nodes, confirm the input and output, pick a name and folder and press “Create LUT 65”. The result is a 65³ .cube plus a notes file.", .es: "Suelta el DRX en la ventana o elígelo. La aplicación trabaja en un proyecto aparte de Resolve, no en el tuyo. Revisa los nodos, confirma la entrada y la salida, elige nombre y carpeta y pulsa «Crear LUT 65». El resultado es un .cube 65³ y un archivo de notas."],
        .helpApplyT: [.ro: "Aplică LUT-ul corect", .en: "Apply the LUT correctly", .es: "Aplicar el LUT correctamente"],
        .helpApplyB: [.ro: "Copiază .cube în folderul de LUT-uri al lui Resolve (Project Settings ▸ Color Management ▸ Lookup Tables ▸ Open LUT Folder), apasă Update Lists și aplică-l pe un nod al clipului, cu interpolare Tetrahedral. Clipul trebuie să fie în spațiul de intrare confirmat; nu dubla transformările de intrare sau ieșire.", .en: "Copy the .cube into Resolve's LUT folder (Project Settings ▸ Color Management ▸ Lookup Tables ▸ Open LUT Folder), press Update Lists and apply it on a node of the clip, with Tetrahedral interpolation. The clip must be in the confirmed input space; do not double input or output transforms.", .es: "Copia el .cube en la carpeta de LUT de Resolve (Project Settings ▸ Color Management ▸ Lookup Tables ▸ Open LUT Folder), pulsa Update Lists y aplícalo en un nodo del clip, con interpolación Tetrahedral. El clip debe estar en el espacio de entrada confirmado; no dupliques transformaciones de entrada o salida."],
        .helpLimitsT: [.ro: "Ce nu poate face un LUT", .en: "What a LUT cannot do", .es: "Lo que un LUT no puede hacer"],
        .helpLimitsB: [.ro: "Un LUT schimbă culoarea pixel cu pixel. Blur, grain, halation, reducerea zgomotului, măști, urmărire și orice depinde de vecini sau de alte cadre nu pot intra. Aplicația exclude ce recunoaște, dar nu poate detecta tot ce conține nodurile native Resolve. LUT-ul 65³ este o aproximare: pot apărea diferențe în culori extreme sau lângă tranziții abrupte.", .en: "A LUT changes colour pixel by pixel. Blur, grain, halation, noise reduction, masks, tracking and anything depending on neighbours or other frames cannot go in. The app excludes what it recognises but cannot detect everything inside native Resolve nodes. A 65³ LUT is an approximation: differences may appear in extreme colours or near abrupt transitions.", .es: "Un LUT cambia el color píxel a píxel. Desenfoque, grano, halación, reducción de ruido, máscaras, seguimiento y todo lo que dependa de vecinos u otros fotogramas no puede entrar. La aplicación excluye lo que reconoce, pero no puede detectar todo lo que hay en nodos nativos de Resolve. Un LUT 65³ es una aproximación: pueden aparecer diferencias en colores extremos o junto a transiciones abruptas."],
        .helpReqT: [.ro: "Cerințe", .en: "Requirements", .es: "Requisitos"],
        .helpReqB: [.ro: "macOS 13 sau mai nou, Mac cu Apple silicon. DaVinci Resolve Studio pornit cu scripting extern activat (verificat cu Resolve Studio 21.2). Efectele OFX din DRX trebuie instalate pe acest Mac; aplicația nu include GDC STYLE Client și nu îl înlocuiește.", .en: "macOS 13 or later, Apple silicon Mac. DaVinci Resolve Studio running with external scripting enabled (verified with Resolve Studio 21.2). The OFX effects in the DRX must be installed on this Mac; the app does not include GDC STYLE Client and does not replace it.", .es: "macOS 13 o posterior, Mac con Apple silicon. DaVinci Resolve Studio abierto con scripting externo activado (verificado con Resolve Studio 21.2). Los efectos OFX del DRX deben estar instalados en este Mac; la aplicación no incluye GDC STYLE Client ni lo sustituye."],
        .helpPrivacyT: [.ro: "Confidențialitate și diagnostic", .en: "Privacy and diagnostics", .es: "Privacidad y diagnóstico"],
        .helpPrivacyB: [.ro: "Totul rulează local. Aplicația nu trimite DRX-uri, LUT-uri sau date personale. Singura conexiune la rețea este verificarea de actualizări. Jurnalul este local; la cerere poți exporta un pachet de diagnostic, pe care îl trimiți tu, dacă vrei.", .en: "Everything runs locally. The app does not send DRX files, LUTs or personal data. The only network connection is the update check. The log is local; on request you can export a diagnostics package, which you send yourself if you wish.", .es: "Todo se ejecuta en local. La aplicación no envía DRX, LUT ni datos personales. La única conexión de red es la comprobación de actualizaciones. El registro es local; si lo pides, puedes exportar un paquete de diagnóstico que envías tú, si quieres."],
        .about: [.ro: "Despre DRX to LUT", .en: "About DRX to LUT", .es: "Acerca de DRX to LUT"],
        .aboutVersion: [.ro: "Versiune %@ (build %@)", .en: "Version %@ (build %@)", .es: "Versión %@ (compilación %@)"],
        .aboutCompat: [.ro: "Verificat cu DaVinci Resolve Studio 21.2. Alte versiuni nu au fost verificate. Funcționează cu un GDC STYLE Client instalat separat; nu îl include.", .en: "Verified with DaVinci Resolve Studio 21.2. Other versions have not been verified. Works with a separately installed GDC STYLE Client; it does not include it.", .es: "Verificado con DaVinci Resolve Studio 21.2. No se han verificado otras versiones. Funciona con un GDC STYLE Client instalado por separado; no lo incluye."],
        .aboutLicense: [.ro: "Licență MIT. Componente terțe: vezi OPEN_SOURCE_NOTICES.", .en: "MIT licence. Third-party components: see OPEN_SOURCE_NOTICES.", .es: "Licencia MIT. Componentes de terceros: ver OPEN_SOURCE_NOTICES."],
        .openSourceNotices: [.ro: "Notificări open source", .en: "Open-source notices", .es: "Avisos de código abierto"],
        .settings: [.ro: "Setări", .en: "Settings", .es: "Ajustes"],
        .general: [.ro: "General", .en: "General", .es: "General"],
        .appearance: [.ro: "Aspect", .en: "Appearance", .es: "Apariencia"],
        .language: [.ro: "Limbă", .en: "Language", .es: "Idioma"],
        .theme: [.ro: "Temă", .en: "Theme", .es: "Tema"],
        .followSystem: [.ro: "Urmează sistemul", .en: "Follow system", .es: "Seguir el sistema"],
        .themeSystem: [.ro: "Sistem", .en: "System", .es: "Sistema"],
        .themeLight: [.ro: "Luminoasă", .en: "Light", .es: "Clara"],
        .themeDark: [.ro: "Întunecată", .en: "Dark", .es: "Oscura"],
        .checkForUpdates: [.ro: "Verifică actualizări…", .en: "Check for updates…", .es: "Buscar actualizaciones…"],
        .quit: [.ro: "Ieșire", .en: "Quit", .es: "Salir"],
        .restoreMenu: [.ro: "Revino la proiectul anterior din Resolve", .en: "Return to the previous Resolve project", .es: "Volver al proyecto anterior de Resolve"],


        .updateAvailable: [.ro: "Versiune nouă disponibilă", .en: "A new version is available", .es: "Hay una versión nueva disponible"],
        .updateNow: [.ro: "Actualizează acum", .en: "Update now", .es: "Actualizar ahora"],
        .updateLater: [.ro: "Mai târziu", .en: "Later", .es: "Más tarde"],
        .upToDate: [.ro: "Ești la zi", .en: "You are up to date", .es: "Estás al día"],
        .updateFailed: [.ro: "Nu am putut verifica actualizări", .en: "Could not check for updates", .es: "No se pudo buscar actualizaciones"],

        .appMoverTitle: [
            .ro: "Mutare în Aplicații?",
            .en: "Move to Applications?",
            .es: "¿Mover a Aplicaciones?"],
        .appMoverMessage: [
            .ro: "DRX to LUT rulează în afara folderului Aplicații. Pentru stabilitate (actualizări automate, permisiuni corecte), se recomandă mutarea în /Applications.",
            .en: "DRX to LUT is running outside the Applications folder. For stability (automatic updates, correct permissions), moving it to /Applications is recommended.",
            .es: "DRX to LUT se está ejecutando fuera de la carpeta Aplicaciones. Para mayor estabilidad (actualizaciones automáticas, permisos correctos), se recomienda moverlo a /Applications."],
        .appMoverMove: [
            .ro: "Mută în Aplicații",
            .en: "Move to Applications",
            .es: "Mover a Aplicaciones"],
        .appMoverNotNow: [
            .ro: "Nu acum",
            .en: "Not now",
            .es: "Ahora no"],
        .appMoverFailedTitle: [
            .ro: "Mutare eșuată",
            .en: "Move failed",
            .es: "No se pudo mover"],
        .appMoverFailedMessage: [
            .ro: "Nu am putut muta aplicația automat (%@). Mut-o manual în /Applications din Finder.",
            .en: "The app could not be moved automatically (%@). Move it to /Applications manually in Finder.",
            .es: "No se pudo mover la aplicación automáticamente (%@). Muévela manualmente a /Applications desde el Finder."],
        .appMoverVersionMismatch: [
            .ro: "copia din /Applications are versiunea %@",
            .en: "the copy in /Applications has version %@",
            .es: "la copia en /Applications tiene la versión %@"],
        .appMoverStillTranslocated: [
            .ro: "copia din /Applications a rămas marcată pentru izolare",
            .en: "the copy in /Applications is still marked for isolation",
            .es: "la copia en /Applications sigue marcada para aislamiento"],
        .appMoverAccessDenied: [
            .ro: "acces refuzat",
            .en: "access denied",
            .es: "acceso denegado"],

        .updateDownloading: [.ro: "Se descarcă actualizarea…", .en: "Downloading the update…", .es: "Descargando la actualización…"],
        .updateVerifying: [.ro: "Se verifică integritatea și semnătura…", .en: "Verifying integrity and signature…", .es: "Verificando integridad y firma…"],
        .updateInstalling: [.ro: "Se instalează…", .en: "Installing…", .es: "Instalando…"],
        .updateWindowTitle: [.ro: "Actualizare", .en: "Update", .es: "Actualización"],
        .updateFailedTitle: [.ro: "Actualizarea a eșuat", .en: "The update failed", .es: "La actualización falló"],
        .updateManualHint: [
            .ro: "Aplicația actuală nu a fost modificată. Poți descărca manual ultima versiune.",
            .en: "The current app was not modified. You can download the latest version manually.",
            .es: "La aplicación actual no se modificó. Puedes descargar la última versión manualmente."],
        .updateOpenPage: [.ro: "Deschide pagina", .en: "Open page", .es: "Abrir la página"],
        .updateManifestInvalid: [.ro: "update.json invalid", .en: "Invalid update.json", .es: "update.json no válido"],
        .updateErrDownload: [.ro: "Descărcarea a eșuat", .en: "Download failed", .es: "La descarga falló"],
        .updateErrInstall: [.ro: "Nu am putut porni instalarea", .en: "Could not start the installation", .es: "No se pudo iniciar la instalación"],
        .updateErrVersion: [
            .ro: "Versiunea %@ nu este mai nouă decât cea instalată (%@). Actualizarea a fost refuzată.",
            .en: "Version %@ is not newer than the installed one (%@). The update was refused.",
            .es: "La versión %@ no es más reciente que la instalada (%@). Se rechazó la actualización."],
        .updateErrNoChecksum: [
            .ro: "Manifestul nu conține suma de control a pachetului. Actualizarea a fost refuzată.",
            .en: "The manifest has no package checksum. The update was refused.",
            .es: "El manifiesto no incluye la suma de control del paquete. Se rechazó la actualización."],
        .updateErrBadURL: [
            .ro: "Adresa de descărcare nu este una de încredere. Actualizarea a fost refuzată.",
            .en: "The download address is not trusted. The update was refused.",
            .es: "La dirección de descarga no es de confianza. Se rechazó la actualización."],
        .updateErrChecksum: [
            .ro: "Pachetul descărcat nu corespunde sumei de control din manifest. Actualizarea a fost refuzată.",
            .en: "The downloaded package does not match the manifest checksum. The update was refused.",
            .es: "El paquete descargado no coincide con la suma de control del manifiesto. Se rechazó la actualización."],
        .updateErrUnsigned: [
            .ro: "Pachetul nu este semnat. Actualizarea a fost refuzată.",
            .en: "The package is not signed. The update was refused.",
            .es: "El paquete no está firmado. Se rechazó la actualización."],
        .updateErrSigner: [
            .ro: "Pachetul este semnat de altcineva decât dezvoltatorul DRX to LUT. Actualizarea a fost refuzată.",
            .en: "The package is signed by someone other than the DRX to LUT developer. The update was refused.",
            .es: "El paquete está firmado por alguien distinto del desarrollador de DRX to LUT. Se rechazó la actualización."],
        .updateErrPayload: [
            .ro: "Conținutul pachetului nu este DRX to LUT în versiunea anunțată. Actualizarea a fost refuzată.",
            .en: "The package content is not DRX to LUT at the announced version. The update was refused.",
            .es: "El contenido del paquete no es DRX to LUT en la versión anunciada. Se rechazó la actualización."],
        .updateErrApp: [
            .ro: "Semnătura aplicației din pachet nu este validă. Actualizarea a fost refuzată.",
            .en: "The signature of the app inside the package is not valid. The update was refused.",
            .es: "La firma de la aplicación dentro del paquete no es válida. Se rechazó la actualización."],
        .updateErrTool: [.ro: "Verificare imposibilă", .en: "Verification not possible", .es: "Verificación imposible"],

        .diagnostics: [.ro: "Diagnostic", .en: "Diagnostics", .es: "Diagnóstico"],
        .openLogsFolder: [.ro: "Deschide folderul de loguri", .en: "Open logs folder", .es: "Abrir la carpeta de registros"],
        .copySessionID: [.ro: "Copiază ID-ul sesiunii", .en: "Copy session ID", .es: "Copiar el ID de sesión"],
        .exportDiagnostics: [.ro: "Exportă diagnosticul…", .en: "Export diagnostics…", .es: "Exportar diagnóstico…"],
        .exportDone: [
            .ro: "Pachetul de diagnostic a fost creat local: %@. Nu a fost trimis nicăieri.",
            .en: "The diagnostics package was created locally: %@. It was not sent anywhere.",
            .es: "El paquete de diagnóstico se creó localmente: %@. No se envió a ningún sitio."],
        .exportFailed: [.ro: "Exportul a eșuat", .en: "Export failed", .es: "La exportación falló"],
        .debugTemporary: [
            .ro: "Jurnal detaliat (o oră)", .en: "Detailed log (one hour)", .es: "Registro detallado (una hora)"],
        .sessionID: [.ro: "Sesiune", .en: "Session", .es: "Sesión"],

        .uninstallSection: [.ro: "Dezinstalare", .en: "Uninstall", .es: "Desinstalación"],
        .uninstallApp: [.ro: "Dezinstalează complet aplicația…", .en: "Uninstall the app completely…", .es: "Desinstalar la aplicación por completo…"],
        .uninstallConfirmTitle: [.ro: "Dezinstalezi DRX to LUT?", .en: "Uninstall DRX to LUT?", .es: "¿Desinstalar DRX to LUT?"],
        .uninstallConfirmBody: [
            .ro: "Se șterg setările și datele DRX to LUT și aplicația se mută la Coș:\n%@",
            .en: "DRX to LUT's settings and data are deleted and the app is moved to the Trash:\n%@",
            .es: "Se borran los ajustes y datos de DRX to LUT y la aplicación se mueve a la Papelera:\n%@"],
        .uninstallConfirmButton: [.ro: "Dezinstalează", .en: "Uninstall", .es: "Desinstalar"],
        .uninstallFailedTitle: [.ro: "Dezinstalarea nu a fost completă", .en: "The uninstall was not complete", .es: "La desinstalación no fue completa"],

        .ok: [.ro: "OK", .en: "OK", .es: "Aceptar"],
        .notAvailable: [.ro: "Indisponibil", .en: "Not available", .es: "No disponible"],
        .unknown: [.ro: "Necunoscut", .en: "Unknown", .es: "Desconocido"],
        .loading: [.ro: "Se încarcă…", .en: "Loading…", .es: "Cargando…"],
        .seconds: [.ro: "secunde", .en: "seconds", .es: "segundos"],
    ]
}


/// Verificarea care face „trilingv integral” o afirmație verificabilă, nu o
/// intenție. Rulată de `scripts/build_app.sh` înainte de orice build.
enum LocalizationAudit {
    /// Cheile cărora le lipsește cel puțin o limbă.
    static func incomplete() -> [(K, [Lang])] {
        K.allCases.compactMap { key in
            let missing = Lang.allCases.filter { L.table[key]?[$0] == nil }
            return missing.isEmpty ? nil : (key, missing)
        }
    }
}
