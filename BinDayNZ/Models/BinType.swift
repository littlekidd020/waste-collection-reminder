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
        case .rubbish: return L("Rubbish")
        case .recycling: return L("Recycling")
        case .foodScraps: return L("Food Scraps")
        case .inorganic: return L("Inorganic Collection")
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
                L("Nappies and sanitary products"),
                L("Polystyrene and bubble wrap"),
                L("Broken crockery and ceramics"),
                L("Vacuum cleaner dust"),
                L("Cold ashes")
            ]
        case .recycling:
            return [
                L("Paper and cardboard (flattened)"),
                L("Plastic bottles and containers (#1, #2, #5)"),
                L("Glass bottles and jars"),
                L("Steel and aluminium cans"),
                L("Tin cans (rinsed)")
            ]
        case .foodScraps:
            return [
                L("Fruit and vegetable scraps"),
                L("Meat, fish, and bones"),
                L("Dairy products"),
                L("Bread, rice, and pasta"),
                L("Tea bags and coffee grounds")
            ]
        case .inorganic:
            return [
                L("Old furniture"),
                L("Whiteware (fridges, washing machines)"),
                L("Mattresses"),
                L("Scrap metal"),
                L("Carpet and underlay")
            ]
        }
    }

    /// Items commonly mistakenly placed in this bin
    var rejectedItems: [String] {
        switch self {
        case .rubbish:
            return [
                L("Recyclable items (use yellow bin)"),
                L("Food scraps (use green bin)"),
                L("Hazardous waste (paint, chemicals)"),
                L("E-waste (batteries, electronics)")
            ]
        case .recycling:
            return [
                L("Plastic bags and soft plastics"),
                L("Food-contaminated containers"),
                L("Drinking glasses and ceramics"),
                L("Styrofoam and polystyrene"),
                L("Nappies")
            ]
        case .foodScraps:
            return [
                L("Plastic bags (even compostable)"),
                L("Liquids and cooking oil"),
                L("Garden waste"),
                L("Pet waste")
            ]
        case .inorganic:
            return [
                L("Hazardous materials (paint, gas bottles)"),
                L("Car parts and tyres"),
                L("Building materials (concrete, timber)"),
                L("Green waste")
            ]
        }
    }

    var localVideoName: String {
        switch self {
        case .rubbish: return "rubbish"
        case .recycling: return "recycling"
        case .foodScraps: return "food-scraps"
        case .inorganic: return "inorganic"
        }
    }

    var videoURL: String {
        // We'll prioritize the local video file once it's added to the bundle
        if let localURL = Bundle.main.url(forResource: localVideoName, withExtension: "mp4") {
            return localURL.absoluteString
        }
        
        // Fallback to YouTube
        switch self {
        case .rubbish: return "https://www.youtube.com/watch?v=AIkjD2vszQo"
        case .recycling: return "https://www.youtube.com/watch?v=42dWHzAqO7E"
        case .foodScraps: return "https://www.youtube.com/watch?v=fCk0RGm-xK8"
        case .inorganic: return "https://www.youtube.com/watch?v=vq5rAaNrevA"
        }
    }
}
