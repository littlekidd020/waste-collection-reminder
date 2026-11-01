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

    /// High-contrast foreground for content placed directly on the bin gradient.
    var gradientForeground: Color {
        switch self {
        case .rubbish: return .white
        case .recycling, .foodScraps, .inorganic: return Color.black.opacity(0.85)
        }
    }

    var rgbComponents: (red: Double, green: Double, blue: Double) {
        switch self {
        case .rubbish: return (0.85, 0.2, 0.2)
        case .recycling: return (0.95, 0.8, 0.1)
        case .foodScraps: return (0.2, 0.75, 0.3)
        case .inorganic: return (0.9, 0.6, 0.1)
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
        case .rubbish: return "trash"
        case .recycling: return "arrow.3.trianglepath"
        case .foodScraps: return "leaf"
        case .inorganic: return "shippingbox"
        }
    }

    /// Reviewed against the linked Auckland Council guidance.
    static let guideReviewDate = DateComponents(
        calendar: Calendar(identifier: .gregorian), year: 2026, month: 9, day: 6
    ).date!

    var acceptedItems: [String] {
        switch self {
        case .rubbish:
            return [
                L("Nappies and sanitary products"),
                L("Plastic and foil wraps"),
                L("Disposable cups, plates and cutlery"),
                L("Polystyrene food containers and trays"),
                L("Broken glass, securely wrapped")
            ]
        case .recycling:
            return [
                L("Paper and cardboard (flattened)"),
                L("Plastic bottles and containers (#1, #2, #5)"),
                L("Glass bottles and jars"),
                L("Tin, steel and aluminium cans")
            ]
        case .foodScraps:
            return [
                L("Fruit and vegetable scraps"),
                L("Meat, fish, and bones"),
                L("Dairy products"),
                L("Bread, rice, and pasta"),
                L("Loose tea leaves and coffee grounds"),
                L("Certified home-compostable bin liners")
            ]
        case .inorganic:
            return [
                L("Furniture, including beds and couches"),
                L("Empty fridges, washing machines and small appliances"),
                L("Carpet in manageable pieces"),
                L("Timber under two metres, with no exposed nails"),
                L("Electronics with batteries removed")
            ]
        }
    }

    var rejectedItems: [String] {
        switch self {
        case .rubbish:
            return [
                L("Recyclable items"),
                L("Hazardous waste (paint, chemicals)"),
                L("Batteries and electronics"),
                L("Hot ashes"),
                L("Garden waste and building materials")
            ]
        case .recycling:
            return [
                L("Plastic bags and soft plastics"),
                L("Food waste and unemptied containers"),
                L("Drinking glasses and ceramics"),
                L("Styrofoam and polystyrene"),
                L("Lids, foil, aerosol cans and drink cartons"),
                L("Nappies, batteries and electronics")
            ]
        case .foodScraps:
            return [
                L("Tea bags"),
                L("Plastic bags and compostable food packaging"),
                L("Garden waste"),
                L("Pet waste"),
                L("Cling film, waxed paper and foil")
            ]
        case .inorganic:
            return [
                L("Batteries, paint, chemicals and gas bottles"),
                L("Car parts and tyres"),
                L("Concrete, tiles and plasterboard"),
                L("Asbestos-containing materials"),
                L("Garden waste, glass and clothing")
            ]
        }
    }

    var guideNotes: [String] {
        switch self {
        case .rubbish:
            return [L("Use your food scraps service where it is available. Check your property's collection instructions for exceptions.")]
        case .recycling:
            return [
                L("Empty and rinse containers, then place them loose in your recycling bin."),
                L("Remove all lids and put them in the rubbish."),
                L("Containers must be wider than 5 cm and smaller than 4 litres. On Aotea / Great Barrier Island, the limit is 5 litres."),
                L("Flat paper and cardboard must be larger than 10 × 14 cm. On Aotea, bundle paper and cardboard beside your recycling crate.")
            ]
        case .foodScraps:
            return [
                L("Use a certified home-compostable bin liner, newspaper or a paper bag if you need a liner. Compostable food packaging is not accepted."),
                L("Apartment and shared-bin collections may have special arrangements. Check with your property manager.")
            ]
        case .inorganic:
            return [
                L("Book with Auckland Council first. Items are collected from inside your property boundary, not the kerbside."),
                L("Put out no more than one cubic metre. Each item must weigh no more than 55 kg and be safe for two people to lift."),
                L("Remove batteries from devices. Keep access clear and follow the date and placement instructions in your booking.")
            ]
        }
    }

    var guideSourceURL: URL {
        let address: String
        switch self {
        case .rubbish:
            address = "https://new.aucklandcouncil.govt.nz/en/rubbish-recycling/bin-requests/what-put-your-rubbish.html"
        case .recycling:
            address = "https://new.aucklandcouncil.govt.nz/en/rubbish-recycling/bin-requests/what-put-your-recycling.html"
        case .foodScraps:
            address = "https://www.aucklandcouncil.govt.nz/rubbish-recycling/Documents/food-scraps-collection-service.pdf"
        case .inorganic:
            address = "https://new.aucklandcouncil.govt.nz/en/rubbish-recycling/inorganic-collections/what-put-out-inorganic-collection.html"
        }
        return URL(string: address)!
    }

    var youTubeVideoID: String? {
        switch self {
        case .rubbish: return nil
        case .recycling: return "42dWHzAqO7E"
        case .foodScraps: return "fCk0RGm-xK8"
        case .inorganic: return "vq5rAaNrevA"
        }
    }

    var videoURL: URL? {
        youTubeVideoID.flatMap { URL(string: "https://www.youtube.com/watch?v=\($0)") }
    }
}
