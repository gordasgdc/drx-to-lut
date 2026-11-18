import Foundation
import AppKit
import SwiftUI

/// Moduri de linie de comandă pentru verificări fără interfață:
///   DRXtoLUT --version
///   DRXtoLUT --l10n-audit            chei lipsă într-o limbă
///   DRXtoLUT --strings <ro|en|es>    toate textele, într-o limbă
///   DRXtoLUT --update-dry-run        verifică manifestul de actualizare
///   DRXtoLUT --backend <comandă…>    rulează backend-ul din pachet și tipărește evenimentele
/// Ies imediat; nu deschid ferestre.
enum CommandLineMode {
    /// `DRXtoLUT --snapshot <png> <ro|en|es> <dark|light|system> <idle|review|done|failed> <lățime> <înălțime> [drx] [folder]`
    /// Deschide fereastra reală, rulează fluxul real (Resolve) până la starea cerută și o
    /// fotografiază prin `screencapture -l`. Folosit pentru capturile din site și documentație.
    @MainActor
    static func snapshotIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), i + 6 < args.count else { return false }
        let path = args[i + 1]
        LocalizationManager.shared.set(.fixed(Lang(rawValue: args[i + 2]) ?? .en))
        ThemeManager.shared.set(AppTheme(rawValue: args[i + 3]) ?? .dark)
        let state = args[i + 4]
        let width = Double(args[i + 5]) ?? 760, height = Double(args[i + 6]) ?? 680
        let drx = i + 7 < args.count ? URL(fileURLWithPath: args[i + 7]) : nil
        let folder = i + 8 < args.count ? URL(fileURLWithPath: args[i + 8]) : nil
        let flow = Converter.shared
        NSApp.setActivationPolicy(.regular)
        let window = NSWindow(contentRect: NSRect(x: 80, y: 80, width: width, height: height),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = L.t(.appName)
        window.contentView = NSHostingView(rootView: MainView().frame(width: width, height: height))
        window.setContentSize(NSSize(width: width, height: height))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        func shoot() {
            let capture = Process()
            capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            capture.arguments = ["-x", "-o", "-l", String(window.windowNumber), path]
            try? capture.run(); capture.waitUntilExit()
            print("snapshot \(path) state=\(state) status=\(capture.terminationStatus)")
            exit(0)
        }
        func wait(for phase: Phase, then next: @escaping () -> Void, tries: Int = 240) {
            if flow.phase == phase { DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { next() }; return }
            if tries == 0 { print("timeout waiting for \(phase)"); exit(2) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { wait(for: phase, then: next, tries: tries - 1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            switch state {
            case "idle":
                flow.refreshStatus()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { shoot() }
            case "review", "done", "failed":
                guard let drx else { print("drx required"); exit(2) }
                if let folder { flow.open(drx); flow.outputFolder = folder } else { flow.open(drx) }
                if state == "failed" { wait(for: .failed, then: shoot) }
                else if state == "review" { wait(for: .review, then: { flow.ioConfirmed = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shoot() } }) }
                else { wait(for: .review, then: { flow.ioConfirmed = true; flow.create(overwrite: true); wait(for: .done, then: { if flow.previousProject != nil { flow.previousProject = "My project" }; shoot() }) }) }
            default: print("stare necunoscută"); exit(2)
            }
        }
        return true
    }

    @MainActor
    static func runIfRequested() {
        let args = CommandLine.arguments
        if args.contains("--version") {
            print("\(AppInfo.version) (\(AppInfo.build))")
            exit(0)
        }
        if args.contains("--l10n-audit") {
            let missing = LocalizationAudit.incomplete()
            for (key, langs) in missing { print("LIPSĂ \(key.rawValue): \(langs.map(\.rawValue).joined(separator: ","))") }
            print("chei=\(K.allCases.count) incomplete=\(missing.count)")
            exit(missing.isEmpty ? 0 : 1)
        }
        if let i = args.firstIndex(of: "--strings"), i + 1 < args.count, let lang = Lang(rawValue: args[i + 1]) {
            for key in K.allCases { print("\(key.rawValue)\t\(L.t(key, lang).replacingOccurrences(of: "\n", with: "\\n"))") }
            exit(0)
        }
        if args.contains("--update-dry-run") {
            Task { @MainActor in
                let result = await UpdateChecker.shared.dryRun()
                print(result.message)
                DiagnosticLog.flush()
                exit(result.ok ? 0 : 2)
            }
            RunLoop.main.run()
        }
        if let i = args.firstIndex(of: "--backend") {
            let rest = Array(args[(i + 1)...])
            let runner = BackendProcess()
            do {
                try runner.start(args: rest, onEvent: { ev in
                    if let data = try? JSONSerialization.data(withJSONObject: ev.raw, options: [.sortedKeys]) { print(String(decoding: data, as: UTF8.self)) }
                }, onExit: { status in
                    DiagnosticLog.flush()
                    exit(status)
                })
            } catch {
                print("backend_missing")
                exit(127)
            }
            RunLoop.main.run()
        }
    }
}
