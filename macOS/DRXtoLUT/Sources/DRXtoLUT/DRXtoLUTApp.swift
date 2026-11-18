import SwiftUI
import AppKit

@main
struct DRXtoLUTApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var loc = LocalizationManager.shared

    init() {
        MainActor.assumeIsolated { CommandLineMode.runIfRequested() }
    }

    var body: some Scene {
        Window(L.t(.appName), id: "main") {
            MainView().id(loc.current)
        }
        .defaultSize(width: 760, height: 680)
        .commands {
            CommandGroup(replacing: .appInfo) { AboutCommand() }
            CommandGroup(replacing: .help) { HelpCommand() }
            CommandGroup(after: .appInfo) {
                Button(L.t(.checkForUpdates)) { UpdateChecker.shared.checkManually() }
                Button(L.t(.restoreMenu)) { Converter.shared.restore() }
            }
        }
        Window(L.t(.helpTitle), id: "help") { HelpView() }.defaultSize(width: 560, height: 560)
        Window(L.t(.about), id: "about") { AboutView() }.windowResizability(.contentSize)
        Settings { SettingsView() }
    }
}

private struct AboutCommand: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View { Button(L.t(.about)) { openWindow(id: "about") } }
}

private struct HelpCommand: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View { Button(L.t(.help)) { openWindow(id: "help") }.keyboardShortcut("?", modifiers: .command) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if MainActor.assumeIsolated({ CommandLineMode.snapshotIfRequested() }) { return }
        _ = ThemeManager.shared
        _ = LocalizationManager.shared
        DiagnosticLog("app").info("Pornire v\(AppInfo.version) (\(AppInfo.build)), sesiune \(DiagnosticLog.sessionID)")
        AppMover.promptIfNeeded()
        UpdateChecker.shared.checkAtLaunch()
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        if let url = urls.first { Task { @MainActor in Converter.shared.open(url) } }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in Converter.shared.cancel() }
        DiagnosticLog("app").info("Oprire")
        DiagnosticLog.flush()
    }
}
