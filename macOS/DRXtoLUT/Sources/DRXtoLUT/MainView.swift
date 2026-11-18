import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject private var flow = Converter.shared
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(flow: flow)
            Divider()
            Group {
                switch flow.phase {
                case .idle: IdleView(flow: flow)
                case .inspecting, .making: ProgressPanel(flow: flow)
                case .review: ReviewView(flow: flow)
                case .done: DoneView(flow: flow)
                case .failed: FailedView(flow: flow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 640, minHeight: 520)
        .background(DM.background)
        .tint(DM.accent)
        .id(loc.current)
        .onAppear { flow.refreshStatus() }
        .alert(L.t(.switchTitle), isPresented: Binding(get: { flow.switchPrompt != nil }, set: { if !$0 { flow.declineSwitch() } })) {
            Button(L.t(.switchConfirm)) { flow.confirmSwitch() }
            Button(L.t(.cancel), role: .cancel) { flow.declineSwitch() }
        } message: {
            Text(String(format: L.t(.switchBody), flow.switchPrompt ?? ""))
        }
        .alert(L.t(.overwriteTitle), isPresented: $flow.overwritePrompt) {
            Button(L.t(.overwriteConfirm), role: .destructive) { flow.create(overwrite: true) }
            Button(L.t(.cancel), role: .cancel) {}
        } message: {
            Text(String(format: L.t(.overwriteBody), "\(flow.name)_65.cube"))
        }
        .alert(flow.notice ?? "", isPresented: Binding(get: { flow.notice != nil }, set: { if !$0 { flow.notice = nil } })) {
            Button(L.t(.ok)) { flow.notice = nil }
        }
    }
}

// MARK: - Antet

private struct HeaderBar: View {
    @ObservedObject var flow: Converter
    var body: some View {
        HStack(spacing: 12) {
            if let icon = AppInfo.icon {
                Image(nsImage: icon).resizable().frame(width: 36, height: 36).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(L.t(.appName)).font(.headline)
                Text(L.t(.appTagline)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 3) {
                ResolveBadge(flow: flow)
                Text("v\(AppInfo.version) (\(AppInfo.build))").font(.caption2.monospacedDigit()).foregroundStyle(.secondary).textSelection(.enabled)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

private struct ResolveBadge: View {
    @ObservedObject var flow: Converter
    var body: some View {
        HStack(spacing: 6) {
            switch flow.resolve {
            case .ready(let v):
                Circle().fill(DM.verified).frame(width: 8, height: 8)
                Text(String(format: L.t(.resolveOK), v)).font(.caption)
            case .off(let message):
                Circle().fill(DM.failure).frame(width: 8, height: 8)
                Text(L.t(.resolveOff)).font(.caption).help(message)
                Button(L.t(.recheck)) { flow.refreshStatus() }.controlSize(.small)
            case .checking, .unknown:
                ProgressView().controlSize(.small)
                Text(L.t(.checking)).font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Început

private struct IdleView: View {
    @ObservedObject var flow: Converter
    @State private var targeted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square").font(.system(size: 34)).foregroundStyle(.secondary).accessibilityHidden(true)
                    Text(L.t(.dropTitle)).font(.title3.weight(.semibold))
                    Text(L.t(.dropSubtitle)).foregroundStyle(.secondary)
                    Button(L.t(.chooseDRX)) { flow.chooseDRX() }
                        .keyboardShortcut("o", modifiers: .command).controlSize(.large)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 28)
                .background(RoundedRectangle(cornerRadius: 14).fill(targeted ? DM.accent.opacity(0.12) : DM.surface.opacity(0.5)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundStyle(targeted ? DM.accent : Color.secondary.opacity(0.5)))
                .onDrop(of: [.fileURL], isTargeted: $targeted) { providers in
                    guard let p = providers.first else { return false }
                    _ = p.loadObject(ofClass: URL.self) { url, _ in
                        if let url { DispatchQueue.main.async { flow.open(url) } }
                    }
                    return true
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(L.t(.dropTitle))

                Card(title: L.t(.howTitle)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L.t(.how1)); Text(L.t(.how2)); Text(L.t(.how3))
                    }
                }
                Card(title: L.t(.reqTitle)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(L.t(.reqResolve), systemImage: "checkmark.seal")
                        Label(L.t(.reqEffects), systemImage: "puzzlepiece.extension")
                    }
                }
            }
            .padding(20).frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
    }
}

struct Card<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            content().font(.callout).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .panel()
    }
}

// MARK: - Progres

private struct ProgressPanel: View {
    @ObservedObject var flow: Converter
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView(value: flow.progress).frame(maxWidth: 420)
                .accessibilityLabel(flow.stage)
                .accessibilityValue("\(Int(flow.progress * 100))%")
            Text(flow.cancelling ? L.t(.cancelling) : flow.stage).foregroundStyle(.secondary)
            Button(L.t(.cancel)) { flow.cancel() }
                .keyboardShortcut(.cancelAction).disabled(flow.cancelling)
            Spacer()
        }.padding()
    }
}

// MARK: - Verificare noduri

private struct ReviewView: View {
    @ObservedObject var flow: Converter

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L.t(.reviewTitle)).font(.title3.weight(.semibold))
                    if let drx = flow.drxURL {
                        Text(String(format: L.t(.reviewFile), drx.lastPathComponent)).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    if !flow.effectsOK { MissingEffects(flow: flow) }
                    VStack(spacing: 0) {
                        ForEach($flow.nodes) { $row in
                            NodeLine(row: $row)
                            if row.id != flow.nodes.last?.id { Divider() }
                        }
                    }
                    .panel()
                    if flow.nodes.contains(where: { $0.cls == .native && $0.include }) {
                        Note(text: L.t(.clsNativeNote), symbol: "exclamationmark.triangle")
                    }
                    Note(text: L.t(.detectionNote), symbol: "info.circle")
                    Card(title: L.t(.ioTitle)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L.t(.ioBody))
                            Toggle(L.t(.ioConfirm), isOn: $flow.ioConfirmed)
                        }
                    }
                    Card(title: L.t(.outName)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TextField(L.t(.outName), text: $flow.name).textFieldStyle(.roundedBorder)
                                Text("_65.cube").foregroundStyle(.secondary).font(.callout.monospaced())
                            }
                            if !flow.name.isEmpty && !flow.nameValid { Text(L.t(.errBadName)).font(.caption).foregroundStyle(DM.failure) }
                            HStack {
                                Text("\(L.t(.outFolder)):").foregroundStyle(.secondary)
                                Text(flow.outputFolder?.path ?? "—").lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                                Spacer(minLength: 8)
                                Button(L.t(.chooseFolder)) { flow.chooseFolder() }
                            }
                        }
                    }
                }
                .padding(20).frame(maxWidth: 820).frame(maxWidth: .infinity)
            }
            Divider()
            HStack {
                Button(L.t(.anotherDRX)) { flow.reset() }
                if !flow.canCreate { Text(L.t(.createHintSelect)).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                Spacer()
                Button(L.t(.createLUT)) { flow.requestCreate() }
                    .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).controlSize(.large).disabled(!flow.canCreate)
            }.padding(.horizontal, 20).padding(.vertical, 10)
        }
    }
}

private struct NodeLine: View {
    @Binding var row: NodeRow
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: $row.include).labelsHidden().disabled(row.locked)
                .accessibilityLabel(String(format: L.t(.nodeIncludeA11y), row.index))
            Text("\(row.index)").font(.callout.monospacedDigit()).foregroundStyle(.secondary).frame(width: 24, alignment: .trailing)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.label.isEmpty ? L.t(.nodeLabelEmpty) : row.label).font(.callout.weight(.medium))
                if !row.tools.isEmpty {
                    Text(row.tools.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                if !row.enabled { Text(L.t(.nodeDisabled)).font(.caption).foregroundStyle(.secondary) }
                else if let note = note { Text(note).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer(minLength: 8)
            Text(badge.0).font(.caption.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(badge.1.opacity(0.18))).foregroundStyle(badge.1)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
    private var badge: (String, Color) {
        switch row.cls {
        case .pixel: return (L.t(.clsPixel), DM.verified)
        case .spatial: return (L.t(.clsSpatial), DM.failure)
        case .unknown: return (L.t(.clsUnknown), DM.warning)
        case .native: return (L.t(.clsNative), DM.warning)
        }
    }
    private var note: String? {
        switch row.cls {
        case .spatial: return L.t(.clsSpatialNote)
        case .unknown: return L.t(.clsUnknownNote)
        default: return nil
        }
    }
}

private struct Note: View {
    let text: String, symbol: String
    var body: some View {
        Label { Text(text).font(.caption).fixedSize(horizontal: false, vertical: true) } icon: { Image(systemName: symbol) }
            .foregroundStyle(.secondary)
    }
}

private struct MissingEffects: View {
    @ObservedObject var flow: Converter
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L.t(.effectsMissingTitle), systemImage: "exclamationmark.octagon.fill").font(.subheadline.weight(.semibold)).foregroundStyle(DM.failure)
            Text(String(format: L.t(.effectsMissingBody), flow.missingInstances)).font(.callout)
            if !flow.missingIDs.isEmpty {
                Text(String(format: L.t(.effectsMissingIDs), flow.missingIDs.joined(separator: ", "))).font(.caption.monospaced()).textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .panel(tint: DM.failure)
    }
}

// MARK: - Final și eșec

private struct DoneView: View {
    @ObservedObject var flow: Converter
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(DM.verified).accessibilityHidden(true)
            Text(L.t(.doneTitle)).font(.title2.weight(.semibold))
            if let cube = flow.resultCube { Text(cube.path).font(.caption.monospaced()).textSelection(.enabled).multilineTextAlignment(.center).padding(.horizontal) }
            Text(L.t(.doneBody)).foregroundStyle(.secondary)
            Text(L.t(.doneNext)).font(.callout).multilineTextAlignment(.center).frame(maxWidth: 520)
            HStack {
                Button(L.t(.openFolder)) { flow.revealResult() }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                Button(L.t(.anotherDRX)) { flow.reset() }
                if let prev = flow.previousProject { Button(String(format: L.t(.restoreProjectNamed), prev)) { flow.restore() } }
            }.padding(.top, 6)
            Spacer()
        }.padding()
    }
}

private struct FailedView: View {
    @ObservedObject var flow: Converter
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40)).foregroundStyle(DM.warning).accessibilityHidden(true)
            Text(L.t(.errTitle)).font(.title3.weight(.semibold))
            Text(flow.message).multilineTextAlignment(.center).frame(maxWidth: 520).textSelection(.enabled)
            HStack {
                if flow.drxURL != nil { Button(L.t(.recheck)) { flow.inspect() } }
                Button(L.t(.anotherDRX)) { flow.reset() }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }
            Spacer()
        }.padding()
    }
}
