import SwiftUI
import UIKit

/// P5 "Linen and clay", chosen 9 November 2026, with its dark counterpart. Every colour in the
/// app comes from here or from a bin's lid (`BinType.lidTone`). Shared with the widget.
enum Palette {
    /// The app background: linen by day, warm charcoal by night.
    static let ground = dynamic(light: 0xF5F0E8, dark: 0x1C1916)
    /// A second, slightly deeper linen for the floor the bins stand on and grouped areas.
    static let surface = dynamic(light: 0xEBE4D9, dark: 0x27221E)
    /// Primary text.
    static let ink = dynamic(light: 0x2B2622, dark: 0xF2ECE3)
    /// Secondary text and labels. Passes 4.5:1 on both grounds.
    static let muted = dynamic(light: 0x6F675F, dark: 0xA69C90)
    /// Hairlines.
    static let line = dynamic(light: 0xD9D1C4, dark: 0x3B342E)
    /// Deep moss, the one non-lid accent: buttons, selection, today.
    static let accent = dynamic(light: 0x35463B, dark: 0x9DBBA6)
    static let onAccent = dynamic(light: 0xF5F0E8, dark: 0x1C1916)
    /// Warm shadow colour; always used at low opacity.
    static let shadow = dynamic(light: 0x4A4036, dark: 0x000000)
    /// Text that must be noticed (errors, destructive actions) without a system red.
    static let attention = dynamic(light: 0x8A3322, dark: 0xE8A090)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// Mixed towards white. Resolves in the current appearance.
    func lighter(_ amount: Double) -> Color { mixed(with: .white, amount) }
    /// Mixed towards a warm near-black.
    func darker(_ amount: Double) -> Color { mixed(with: Color(hex: 0x1E1A16), amount) }

    private func mixed(with other: Color, _ t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(.sRGB, red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, opacity: 1)
    }
}
