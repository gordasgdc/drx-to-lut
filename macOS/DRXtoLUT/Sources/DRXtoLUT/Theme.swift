import SwiftUI
import AppKit

/// Jetoane de design din familia GDC (direcția DataMover: accent cald, culori semantice,
/// panouri ridicate în ambele teme). Fără culori literale pe controale (Regula 37).
enum DM {
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
    static let accent = dynamic(light: NSColor(srgbRed: 0.72, green: 0.40, blue: 0.16, alpha: 1),
                                dark: NSColor(srgbRed: 0.93, green: 0.60, blue: 0.32, alpha: 1))
    static let verified = dynamic(light: NSColor(srgbRed: 0.10, green: 0.52, blue: 0.27, alpha: 1),
                                  dark: NSColor(srgbRed: 0.35, green: 0.80, blue: 0.48, alpha: 1))
    static let warning = dynamic(light: NSColor(srgbRed: 0.70, green: 0.45, blue: 0.00, alpha: 1),
                                 dark: NSColor(srgbRed: 0.98, green: 0.75, blue: 0.25, alpha: 1))
    static let failure = dynamic(light: NSColor(srgbRed: 0.75, green: 0.15, blue: 0.15, alpha: 1),
                                 dark: NSColor(srgbRed: 1.00, green: 0.45, blue: 0.42, alpha: 1))
    static let surface = dynamic(light: NSColor(white: 1, alpha: 1), dark: NSColor(white: 0.235, alpha: 1))
    static let border = dynamic(light: NSColor(white: 0, alpha: 0.14), dark: NSColor(white: 1, alpha: 0.10))
    static let background = Color(nsColor: .windowBackgroundColor)
}

struct Panel: ViewModifier {
    var tint: Color? = nil
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 12).fill(tint?.opacity(0.10) ?? DM.surface))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(tint?.opacity(0.4) ?? DM.border, lineWidth: 1))
    }
}
extension View { func panel(tint: Color? = nil) -> some View { modifier(Panel(tint: tint)) } }
