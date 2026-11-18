import SwiftUI
import AppKit

enum AppInfo {
    /// Pictograma din pachet, fără masca adăugată de sistem pentru `applicationIconImage`.
    static var icon: NSImage? { Bundle.main.image(forResource: "AppIcon") ?? NSApp.applicationIconImage }
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?" }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?" }
}

struct HelpView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    private var sections: [(K, K)] {
        [(.helpExportT, .helpExportB), (.helpUseT, .helpUseB), (.helpApplyT, .helpApplyB),
         (.helpLimitsT, .helpLimitsB), (.helpReqT, .helpReqB), (.helpPrivacyT, .helpPrivacyB)]
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L.t(.helpTitle)).font(.title2.weight(.semibold))
                ForEach(Array(sections.enumerated()), id: \.offset) { _, s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L.t(s.0)).font(.headline).accessibilityAddTraits(.isHeader)
                        Text(L.t(s.1)).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(24).frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
        }
        .frame(minWidth: 480, minHeight: 420)
        .id(loc.current)
    }
}

struct AboutView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    var body: some View {
        VStack(spacing: 10) {
            if let icon = AppInfo.icon { Image(nsImage: icon).resizable().frame(width: 96, height: 96).accessibilityHidden(true) }
            Text(L.t(.appName)).font(.title2.weight(.semibold))
            Text(String(format: L.t(.aboutVersion), AppInfo.version, AppInfo.build)).font(.callout.monospacedDigit()).textSelection(.enabled)
            Text(L.t(.aboutCompat)).font(.caption).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(L.t(.aboutLicense)).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            HStack {
                Button(L.t(.checkForUpdates)) { UpdateChecker.shared.checkManually() }
                Button(L.t(.openSourceNotices)) {
                    if let url = Bundle.main.url(forResource: "OPEN_SOURCE_NOTICES", withExtension: "md") { NSWorkspace.shared.open(url) }
                }
            }.padding(.top, 4)
            Text("© 2026 Dumitru Cristinel Gordas (GDC)").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(24).frame(width: 420)
        .id(loc.current)
    }
}

struct SettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var verbose = DiagnosticLog.verbose

    private func exportDiagnostics() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "DRXtoLUT-\(AppInfo.version)-diagnostic-\(DiagnosticLog.sessionID).zip"
        panel.allowedContentTypes = [.zip]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let alert = NSAlert()
        do {
            try DiagnosticExporter.export(to: url, settings: ["language": localization.preference.storageValue, "theme": theme.current.rawValue])
            alert.messageText = L.t(.exportDiagnostics)
            alert.informativeText = String(format: L.t(.exportDone), url.path)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            DiagnosticLog("diagnostic").error("Export eșuat: \(error)")
            alert.alertStyle = .warning
            alert.messageText = L.t(.exportFailed)
            alert.informativeText = error.localizedDescription
        }
        alert.addButton(withTitle: L.t(.ok))
        alert.runModal()
    }

    var body: some View {
        Form {
            Section(L.t(.general)) {
                Picker(L.t(.language), selection: Binding(get: { localization.preference }, set: { localization.set($0) })) {
                    Text(L.t(.followSystem)).tag(LangPreference.system)
                    Divider()
                    ForEach(Lang.allCases) { Text($0.nativeName).tag(LangPreference.fixed($0)) }
                }
                Picker(L.t(.theme), selection: Binding(get: { theme.current }, set: { theme.set($0) })) {
                    Text(L.t(.themeSystem)).tag(AppTheme.system)
                    Text(L.t(.themeLight)).tag(AppTheme.light)
                    Text(L.t(.themeDark)).tag(AppTheme.dark)
                }
                Button(L.t(.checkForUpdates)) { UpdateChecker.shared.checkManually() }
            }
            Section(L.t(.diagnostics)) {
                Toggle(L.t(.debugTemporary), isOn: $verbose).onChange(of: verbose) { DiagnosticLog.setVerbose($0) }
                Text("\(L.t(.sessionID)): \(DiagnosticLog.sessionID) · v\(DiagnosticLog.appVersion)").font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                Button(L.t(.openLogsFolder)) { NSWorkspace.shared.open(DiagnosticLog.directory) }
                Button(L.t(.copySessionID)) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(DiagnosticLog.sessionID, forType: .string)
                }
                Button(L.t(.exportDiagnostics)) { exportDiagnostics() }
            }
            Section(L.t(.uninstallSection)) {
                Button(L.t(.uninstallApp), role: .destructive) { SelfUninstaller.confirmAndUninstall() }
            }
        }
        .formStyle(.grouped).frame(width: 440).tint(DM.accent).id(localization.current)
    }
}
