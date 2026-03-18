import Foundation
import SwiftUI

/// Represents the different types of waste bins used across New Zealand councils.
enum BinType: String, Codable, CaseIterable, Identifiable {
    case rubbish
    case recycling
    case foodScraps
    case inorganic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rubbish: return String(localized: "Rubbish")
        case .recycling: return String(localized: "Recycling")
        case .foodScraps: return String(localized: "Food Scraps")
        case .inorganic: return String(localized: "Inorganic Collection")
        }
    }

    var color: Color {
        switch self {
        case .rubbish: return .red
        case .recycling: return .yellow
        case .foodScraps: return .green
        case .inorganic: return .orange
        }
    }

    /// A darker shade for text/icons on light backgrounds
    var darkColor: Color {
        switch self {
        case .rubbish: return Color(red: 0.7, green: 0.1, blue: 0.1)
        case .recycling: return Color(red: 0.7, green: 0.6, blue: 0.0)
        case .foodScraps: return Color(red: 0.1, green: 0.6, blue: 0.2)
        case .inorganic: return Color(red: 0.8, green: 0.5, blue: 0.0)
        }
    }

    /// Gradient colours for card backgrounds
    var gradient: LinearGradient {
        switch self {
        case .rubbish:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.2, blue: 0.2), Color(red: 0.6, green: 0.1, blue: 0.1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .recycling:
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.8, blue: 0.1), Color(red: 0.8, green: 0.65, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .foodScraps:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.75, blue: 0.3), Color(red: 0.1, green: 0.55, blue: 0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .inorganic:
            return LinearGradient(
                colors: [Color(red: 0.9, green: 0.6, blue: 0.1), Color(red: 0.75, green: 0.45, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var icon: String {
        switch self {
        case .rubbish: return "🔴"
        case .recycling: return "🟡"
        case .foodScraps: return "🟢"
        case .inorganic: return "📦"
        }
    }

    var systemImage: String {
        switch self {
        case .rubbish: return "trash.fill"
        case .recycling: return "arrow.3.trianglepath"
        case .foodScraps: return "leaf.fill"
        case .inorganic: return "shippingbox.fill"
        }
    }

    /// Items accepted in this bin type
    var acceptedItems: [String] {
        switch self {
        case .rubbish:
            return [
                String(localized: "Nappies and sanitary products"),
                String(localized: "Polystyrene and bubble wrap"),
                String(localized: "Broken crockery and ceramics"),
                String(localized: "Vacuum cleaner dust"),
                String(localized: "Cold ashes")
            ]
        case .recycling:
            return [
                String(localized: "Paper and cardboard (flattened)"),
                String(localized: "Plastic bottles and containers (#1, #2, #5)"),
                String(localized: "Glass bottles and jars"),
                String(localized: "Steel and aluminium cans"),
                String(localized: "Tin cans (rinsed)")
            ]
        case .foodScraps:
            return [
                String(localized: "Fruit and vegetable scraps"),
                String(localized: "Meat, fish, and bones"),
                String(localized: "Dairy products"),
                String(localized: "Bread, rice, and pasta"),
                String(localized: "Tea bags and coffee grounds")
            ]
        case .inorganic:
            return [
                String(localized: "Old furniture"),
                String(localized: "Whiteware (fridges, washing machines)"),
                String(localized: "Mattresses"),
                String(localized: "Scrap metal"),
                String(localized: "Carpet and underlay")
            ]
        }
    }

    /// Items commonly mistakenly placed in this bin
    var rejectedItems: [String] {
        switch self {
        case .rubbish:
            return [
                String(localized: "Recyclable items (use yellow bin)"),
                String(localized: "Food scraps (use green bin)"),
                String(localized: "Hazardous waste (paint, chemicals)"),
                String(localized: "E-waste (batteries, electronics)")
            ]
        case .recycling:
            return [
                String(localized: "Plastic bags and soft plastics"),
                String(localized: "Food-contaminated containers"),
                String(localized: "Drinking glasses and ceramics"),
                String(localized: "Styrofoam and polystyrene"),
                String(localized: "Nappies")
            ]
        case .foodScraps:
            return [
                String(localized: "Plastic bags (even compostable)"),
                String(localized: "Liquids and cooking oil"),
                String(localized: "Garden waste"),
                String(localized: "Pet waste")
            ]
        case .inorganic:
            return [
                String(localized: "Hazardous materials (paint, gas bottles)"),
                String(localized: "Car parts and tyres"),
                String(localized: "Building materials (concrete, timber)"),
                String(localized: "Green waste")
            ]
        }
    }
}
