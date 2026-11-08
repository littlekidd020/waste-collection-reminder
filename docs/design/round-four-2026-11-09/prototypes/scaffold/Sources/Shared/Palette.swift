import SwiftUI

/// P5 "Linen and clay", chosen 9 November 2026. Every colour in the prototype comes from here.
enum Palette {
    static let ground   = Color(hex: 0xF5F0E8)   // linen, the app background
    static let surface  = Color(hex: 0xEBE4D9)   // a second, slightly deeper linen for grouped areas
    static let ink      = Color(hex: 0x2B2622)   // primary text
    static let muted    = Color(hex: 0x6F675F)   // secondary text, labels
    static let line     = Color(hex: 0xD9D1C4)   // hairlines
    static let accent   = Color(hex: 0x35463B)   // deep moss, the one non-lid accent (buttons, selection)
    static let onAccent = Color(hex: 0xF5F0E8)
    static let shadow   = Color(hex: 0x4A4036)   // warm shadow colour; use at low opacity
}

enum Bin: String, CaseIterable, Identifiable {
    case rubbish, recycling, foodScraps, glass
    var id: String { rawValue }

    var name: String {
        switch self {
        case .rubbish: return "Rubbish"
        case .recycling: return "Recycling"
        case .foodScraps: return "Food scraps"
        case .glass: return "Glass"
        }
    }

    /// Physical lid colour, toned for P5.
    var lid: Color {
        switch self {
        case .rubbish: return Color(hex: 0xC4573F)
        case .recycling: return Color(hex: 0xD9A441)
        case .foodScraps: return Color(hex: 0x6E9A5B)
        case .glass: return Color(hex: 0x5A80A8)
        }
    }

    /// Pale tint of the lid colour, for backgrounds behind deep text.
    var tint: Color {
        switch self {
        case .rubbish: return Color(hex: 0xF8DDD5)
        case .recycling: return Color(hex: 0xF6E6BC)
        case .foodScraps: return Color(hex: 0xDCE8D2)
        case .glass: return Color(hex: 0xD9E3F0)
        }
    }

    /// Deep version of the lid colour, the only one allowed as text (passes 5:1 on its tint).
    var deep: Color {
        switch self {
        case .rubbish: return Color(hex: 0x8A3322)
        case .recycling: return Color(hex: 0x6E4F0C)
        case .foodScraps: return Color(hex: 0x2F5A2B)
        case .glass: return Color(hex: 0x2C4A6E)
        }
    }

    var symbol: String {
        switch self {
        case .rubbish: return "trash"
        case .recycling: return "arrow.3.trianglepath"
        case .foodScraps: return "leaf"
        case .glass: return "wineglass"
        }
    }

    var frequency: String {
        switch self {
        case .rubbish, .foodScraps: return "Weekly"
        case .recycling, .glass: return "Fortnightly"
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
