import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum NodeClass: String {
    case pixel, spatial, unknown, native
}

struct NodeRow: Identifiable {
    let index: Int
    let label: String
    let tools: [String]
    let enabled: Bool
    let cls: NodeClass
    var include: Bool
    var id: Int { index }
    /// Nodurile spațiale sau dezactivate în DRX nu pot fi incluse.
    var locked: Bool { cls == .spatial || !enabled }
}

enum Phase { case idle, inspecting, review, making, done, failed }

enum ResolveStatus: Equatable {
    case unknown, checking
    case ready(version: String)
    case off(message: String)
}

/// Starea fluxului: DRX → noduri → LUT. Toată munca cu Resolve o face
/// backend-ul (proces copil); aici doar traducem evenimentele în stare.
@MainActor
final class Converter: ObservableObject {
    static let shared = Converter()
    private let log = DiagnosticLog("flow")

    @Published var phase: Phase = .idle
    @Published var resolve: ResolveStatus = .unknown
    @Published var drxURL: URL?
    @Published var nodes: [NodeRow] = []
    @Published var missingInstances = 0
    @Published var missingIDs: [String] = []
    @Published var ioConfirmed = false
    @Published var name = ""
    @Published var outputFolder: URL?
    @Published var progress = 0.0
    @Published var stage = ""
    @Published var cancelling = false
    @Published var message = ""
    @Published var resultCube: URL?
    @Published var previousProject: String?
    @Published var switchPrompt: String?
    @Published var overwritePrompt = false
    @Published var notice: String?

    private var runner: BackendProcess?
    private var switchConfirmed = false
    private var sawTerminal = false

    // MARK: - Stare

    var included: [NodeRow] { nodes.filter { $0.include } }
    var effectsOK: Bool { missingInstances == 0 && missingIDs.isEmpty }
    var nameValid: Bool {
        !name.isEmpty && !name.hasPrefix(".") && !name.contains(where: { "/\\:".contains($0) })
    }
    var canCreate: Bool {
        phase == .review && effectsOK && ioConfirmed && nameValid && outputFolder != nil && !included.isEmpty
    }
    var busy: Bool { phase == .inspecting || phase == .making }

    // MARK: - Resolve

    func refreshStatus() {
        guard !busy, runner == nil else { return }
        resolve = .checking
        run(["check"]) { [weak self] ev in
            guard let self else { return }
            switch ev.type {
            case "check":
                if ev.raw["running"] as? Bool == true {
                    self.resolve = .ready(version: ev.string("resolve") ?? "?")
                    self.previousProject = ev.string("previous")
                } else {
                    self.resolve = .off(message: L.t(.errResolveNotRunning))
                }
            case "error":
                self.resolve = .off(message: self.text(for: ev))
            default: break
            }
        } onExit: { [weak self] _ in
            if case .checking = self?.resolve { self?.resolve = .off(message: L.t(.errInternal)) }
        }
    }

    // MARK: - Pași

    func open(_ url: URL) {
        guard !busy else { return }
        guard url.pathExtension.lowercased() == "drx" else {
            notice = L.t(.dropNotDRX)
            return
        }
        drxURL = url
        name = url.deletingPathExtension().lastPathComponent
        outputFolder = url.deletingLastPathComponent()
        ioConfirmed = false
        switchConfirmed = false
        message = ""
        inspect()
    }

    func chooseDRX() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let type = UTType(filenameExtension: "drx") { panel.allowedContentTypes = [type] }
        if panel.runModal() == .OK, let url = panel.url { open(url) }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = outputFolder
        if panel.runModal() == .OK, let url = panel.url { outputFolder = url }
    }

    func inspect() {
        guard let drx = drxURL else { return }
        phase = .inspecting
        progress = 0
        stage = L.t(.inspecting)
        nodes = []
        missingInstances = 0
        missingIDs = []
        var args = ["inspect", drx.path]
        if switchConfirmed { args.append("--allow-switch") }
        log.info("Inspectare DRX (\(drx.lastPathComponent))")
        run(args) { [weak self] ev in self?.handleInspect(ev) } onExit: { [weak self] status in
            guard let self, self.phase == .inspecting else { return }
            self.fail(L.t(status == 3 ? .cancelled : .errBackendMissing))
        }
    }

    private func handleInspect(_ ev: BackendEvent) {
        switch ev.type {
        case "progress":
            progress = Double(ev.int("pct") ?? 0) / 100
            stage = stageText(ev.string("stage"))
        case "nodes":
            let rows = (ev.raw["nodes"] as? [[String: Any]]) ?? []
            nodes = rows.map { r in
                let cls = NodeClass(rawValue: r["cls"] as? String ?? "") ?? .native
                let enabled = r["enabled"] as? Bool ?? true
                // Implicit: incluse doar nodurile active și sigure. „Necunoscut”
                // și „spațial” rămân în afară până decide utilizatorul (necunoscut)
                // sau pentru totdeauna (spațial).
                return NodeRow(index: (r["index"] as? NSNumber)?.intValue ?? 0, label: r["label"] as? String ?? "",
                               tools: (r["tools"] as? [String]) ?? [], enabled: enabled, cls: cls,
                               include: enabled && (cls == .pixel || cls == .native))
            }
            missingInstances = ev.int("missing_instances") ?? 0
            missingIDs = ev.strings("missing_ids")
            if case .ready = resolve {} else { resolve = .ready(version: ev.string("resolve") ?? "?") }
            phase = .review
        case "error":
            if ev.code == "project_switch_required" {
                phase = .idle
                switchPrompt = ev.string("project") ?? "?"
            } else {
                fail(text(for: ev))
            }
        default: break
        }
    }

    func confirmSwitch() {
        switchPrompt = nil
        switchConfirmed = true
        inspect()
    }

    func declineSwitch() {
        switchPrompt = nil
        reset()
    }

    func requestCreate() {
        guard canCreate, let folder = outputFolder else { return }
        let target = folder.appendingPathComponent("\(name)_65.cube")
        if FileManager.default.fileExists(atPath: target.path) { overwritePrompt = true } else { create(overwrite: false) }
    }

    func create(overwrite: Bool) {
        overwritePrompt = false
        guard let drx = drxURL, let folder = outputFolder else { return }
        let excluded = nodes.filter { !$0.include }.map { String($0.index) }.joined(separator: ",")
        var args = ["make", drx.path, folder.path, name, "--exclude", excluded, "--lang", LocalizationManager.shared.current.rawValue, "--io-confirmed"]
        if overwrite { args.append("--overwrite") }
        if switchConfirmed { args.append("--allow-switch") }
        phase = .making
        progress = 0
        stage = ""
        cancelling = false
        sawTerminal = false
        log.info("Creare LUT: \(included.count) noduri incluse din \(nodes.count)")
        run(args) { [weak self] ev in self?.handleMake(ev) } onExit: { [weak self] status in
            guard let self, self.phase == .making else { return }
            if status == 3 || self.cancelling {
                self.notice = L.t(.cancelled)
                self.phase = .review
            } else {
                self.fail(L.t(.errBackendMissing))
            }
        }
    }

    private func handleMake(_ ev: BackendEvent) {
        switch ev.type {
        case "progress":
            progress = Double(ev.int("pct") ?? 0) / 100
            stage = stageText(ev.string("stage"))
        case "done":
            progress = 1
            resultCube = ev.string("cube").map { URL(fileURLWithPath: $0) }
            phase = .done
            log.info("LUT creat")
            refreshAfterRun()
        case "cancelled":
            notice = L.t(.cancelled)
            phase = .review
        case "error":
            if ev.code == "out_exists" {
                phase = .review
                overwritePrompt = true
            } else {
                fail(text(for: ev))
            }
        default: break
        }
    }

    func cancel() {
        guard phase == .making || phase == .inspecting else { return }
        cancelling = true
        runner?.cancel()
    }

    func restore() {
        guard !busy, runner == nil else { return }
        run(["restore"]) { [weak self] ev in
            guard let self else { return }
            if ev.type == "restored" {
                self.notice = String(format: L.t(.restored), ev.string("project") ?? "?")
                self.previousProject = nil
            } else if ev.type == "error" {
                self.notice = self.text(for: ev)
            }
        } onExit: { _ in }
    }

    func reset() {
        guard !busy else { return }
        phase = .idle
        drxURL = nil
        nodes = []
        resultCube = nil
        message = ""
        switchConfirmed = false
        refreshStatus()
    }

    func revealResult() {
        if let url = resultCube { NSWorkspace.shared.activateFileViewerSelecting([url]) }
    }

    // MARK: - Intern

    private func refreshAfterRun() {
        // `check` după un `make` reușit: aflăm proiectul anterior pentru „Revino”.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.refreshStatus() }
    }

    private func fail(_ text: String) {
        message = text
        phase = .failed
        log.warning("Eșec: \(text)")
    }

    private func run(_ args: [String], onEvent: @escaping (BackendEvent) -> Void, onExit: @escaping (Int32) -> Void) {
        let process = BackendProcess()
        runner = process
        do {
            try process.start(args: args, onEvent: { ev in
                if ev.type == "error" { DiagnosticLog("backend").warning("Eroare backend: \(ev.code ?? "?")") }
                onEvent(ev)
            }, onExit: { [weak self] status in
                self?.runner = nil
                onExit(status)
            })
        } catch {
            runner = nil
            DiagnosticLog("backend").error("Pornire eșuată: \(error.localizedDescription)")
            if args.first == "check" { resolve = .off(message: L.t(.errBackendMissing)) } else { fail(L.t(.errBackendMissing)) }
        }
    }

    private func stageText(_ stage: String?) -> String {
        switch stage {
        case "reading_drx": return L.t(.stageReadingDrx)
        case "connecting": return L.t(.stageConnecting)
        case "opening_project": return L.t(.stageOpeningProject)
        case "building_timeline": return L.t(.stageBuildingTimeline)
        case "applying_drx": return L.t(.stageApplyingDrx)
        case "rendering": return L.t(.stageRendering)
        case "writing": return L.t(.stageWriting)
        default: return self.stage
        }
    }

    func text(for ev: BackendEvent) -> String {
        let code = ev.code ?? "internal"
        switch code {
        case "resolve_not_running": return L.t(.errResolveNotRunning)
        case "resolve_not_installed": return L.t(.errResolveNotInstalled)
        case "scripting_unavailable": return L.t(.errScripting)
        case "project_open_failed": return L.t(.errProjectOpen)
        case "project_setup_failed": return L.t(.errProjectSetup)
        case "nothing_to_restore": return L.t(.errNothingToRestore)
        case "previous_not_found": return String(format: L.t(.errPreviousNotFound), ev.string("project") ?? "?")
        case "restore_failed": return String(format: L.t(.errRestoreFailed), ev.string("project") ?? "?")
        case "drx_invalid":
            switch ev.string("reason") {
            case "size": return L.t(.errDrxSize)
            case "encoding": return L.t(.errDrxEncoding)
            case "not_drx": return L.t(.errDrxNotDrx)
            case "no_grade": return L.t(.errDrxNoGrade)
            default: return L.t(.errDrxCorrupt)
            }
        case "drx_unreadable": return L.t(.errDrxUnreadable)
        case "drx_unsupported": return L.t(.errDrxUnsupported)
        case "drx_rejected": return L.t(.errDrxRejected)
        case "effects_missing": return String(format: L.t(.effectsMissingBody), ev.int("count") ?? 0)
        case "bad_name": return L.t(.errBadName)
        case "io_not_confirmed": return L.t(.errIoNotConfirmed)
        case "nothing_included": return L.t(.errNothingIncluded)
        case "render_failed": return L.t(.errRenderFailed)
        case "render_constant": return L.t(.errRenderConstant)
        case "render_unreadable": return L.t(.errRenderUnreadable)
        case "cube_invalid": return L.t(.errCubeInvalid)
        case "lattice_import_failed": return L.t(.errLatticeImport)
        case "timeline_failed": return L.t(.errTimeline)
        case "graph_unreadable": return L.t(.errGraph)
        case "playhead": return L.t(.errPlayhead)
        case "internal": return L.t(.errInternal)
        default: return String(format: L.t(.errUnknownCode), code)
        }
    }
}
