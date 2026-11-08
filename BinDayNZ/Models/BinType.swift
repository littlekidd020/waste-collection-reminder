import Foundation
import SwiftUI
import UIKit

/// The kerbside bins New Zealand councils offer. Rubbish, recycling, glass and organics follow the
/// national lid colours standardised in 2024; inorganic is Auckland's booked service.
enum BinType: String, Codable, CaseIterable, Identifiable {
    case rubbish
    case recycling
    case glass
    case foodScraps
    case gardenWaste
    case organics
    case inorganic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rubbish: return L("Rubbish")
        case .recycling: return L("Recycling")
        case .glass: return L("Glass")
        case .foodScraps: return L("Food Scraps")
        case .gardenWaste: return L("Garden Waste")
        case .organics: return L("Food and Garden Waste")
        case .inorganic: return L("Inorganic Collection")
        }
    }

    /// The lid colour as text: deep on linen, light on charcoal, so it passes 4.5:1 on both grounds.
    var color: Color { lidDeep }

    /// The physical lid colour, toned for the Linen and clay palette and identical in both
    /// appearances. Only lid spheres, rendered props and tints carry it; it is never text.
    var lidTone: Color { Color(hex: lidHex) }

    /// Legacy name for `lidTone`, kept for the widget's older call sites.
    var lidFill: Color { lidTone }

    /// A pale wash of the lid colour for backgrounds behind `lidDeep` text.
    var lidTint: Color {
        switch self {
        case .rubbish: return Palette.dynamic(light: 0xF8DDD5, dark: 0x3B221C)
        case .recycling: return Palette.dynamic(light: 0xF6E6BC, dark: 0x3A2F15)
        case .glass: return Palette.dynamic(light: 0xD9E3F0, dark: 0x1F2A38)
        case .foodScraps, .organics: return Palette.dynamic(light: 0xDCE8D2, dark: 0x22301E)
        case .gardenWaste: return Palette.dynamic(light: 0xE6E9CF, dark: 0x2E3119)
        case .inorganic: return Palette.dynamic(light: 0xF3E2CF, dark: 0x3A2A18)
        }
    }

    /// The lid colour at text strength: deep by day, light by night.
    var lidDeep: Color {
        switch self {
        case .rubbish: return Palette.dynamic(light: 0x8A3322, dark: 0xE8A090)
        case .recycling: return Palette.dynamic(light: 0x6E4F0C, dark: 0xE6C67A)
        case .glass: return Palette.dynamic(light: 0x2C4A6E, dark: 0x9FB8D6)
        case .foodScraps, .organics: return Palette.dynamic(light: 0x2F5A2B, dark: 0xA9C79A)
        case .gardenWaste: return Palette.dynamic(light: 0x4F5A14, dark: 0xCBD38A)
        case .inorganic: return Palette.dynamic(light: 0x7A4E1C, dark: 0xE6B985)
        }
    }

    private var lidHex: UInt32 {
        switch self {
        case .rubbish: return 0xC4573F
        case .recycling: return 0xD9A441
        case .glass: return 0x5A80A8
        case .foodScraps, .organics: return 0x6E9A5B
        case .gardenWaste: return 0x93A24E
        case .inorganic: return 0xC98B4A
        }
    }

    /// Glyph colour on `lidTone`.
    var lidForeground: Color {
        switch self {
        case .recycling, .gardenWaste: return Color(hex: 0x2B2622).opacity(0.85)
        case .rubbish, .glass, .foodScraps, .organics, .inorganic: return .white
        }
    }

    var icon: String {
        switch self {
        case .rubbish: return "🔴"
        case .recycling: return "🟡"
        case .glass: return "🔵"
        case .foodScraps: return "🟢"
        case .gardenWaste: return "🌿"
        case .organics: return "🟢"
        case .inorganic: return "📦"
        }
    }

    var systemImage: String {
        switch self {
        case .rubbish: return "trash"
        case .recycling: return "arrow.3.trianglepath"
        case .glass: return "wineglass"
        case .foodScraps: return "leaf"
        case .gardenWaste: return "tree"
        case .organics: return "carrot"
        case .inorganic: return "shippingbox"
        }
    }

    /// Reviewed against the linked Auckland Council guidance and the national standard materials list.
    static let guideReviewDate = DateComponents(
        calendar: Calendar(identifier: .gregorian), year: 2026, month: 9, day: 6
    ).date!

    /// The national list. Councils with a separate glass bin get a tailored recycling list in `BinGuide`.
    var acceptedItems: [String] {
        switch self {
        case .glass:
            return [
                L("Glass bottles and jars"),
                L("Clear, green and brown glass"),
                L("Rinsed, with lids removed")
            ]
        case .gardenWaste:
            return [
                L("Grass clippings and leaves"),
                L("Small prunings and branches"),
                L("Weeds and flowers")
            ]
        case .organics:
            return [
                L("Fruit and vegetable scraps"),
                L("Meat, fish, and bones"),
                L("Bread, rice, and pasta"),
                L("Grass clippings and leaves"),
                L("Small prunings and branches")
            ]
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
        case .glass:
            return [
                L("Drinking glasses and ceramics"),
                L("Window glass and mirrors"),
                L("Light bulbs and heat-proof glass"),
                L("Broken glass, securely wrapped")
            ]
        case .gardenWaste:
            return [
                L("Soil, stones and treated timber"),
                L("Flax, bamboo and large branches"),
                L("Plastic bags and soft plastics"),
                L("Pet waste")
            ]
        case .organics:
            return [
                L("Plastic bags and compostable food packaging"),
                L("Soil, stones and treated timber"),
                L("Flax, bamboo and large branches"),
                L("Pet waste")
            ]
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

    /// Auckland wording for the shared bins; `BinGuide` swaps in national wording for other councils.
    var guideNotes: [String] {
        switch self {
        case .glass:
            return [L("Put glass loose in the crate, not in bags. Lids go in the rubbish.")]
        case .gardenWaste:
            return [L("Garden waste collections are often optional and may need a subscription with your council.")]
        case .organics:
            return [L("Use a certified home-compostable bin liner, newspaper or a paper bag if you need a liner. Compostable food packaging is not accepted.")]
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

    /// Auckland Council's page for this bin. Other councils' sources come from `BinGuide`.
    var aucklandGuideURL: URL {
        let address: String
        switch self {
        case .glass, .gardenWaste, .organics:
            address = "https://www.aucklandcouncil.govt.nz/rubbish-recycling"
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
        case .rubbish, .glass, .gardenWaste, .organics: return nil
        case .recycling: return "42dWHzAqO7E"
        case .foodScraps: return "fCk0RGm-xK8"
        case .inorganic: return "vq5rAaNrevA"
        }
    }

    var videoURL: URL? {
        youTubeVideoID.flatMap { URL(string: "https://www.youtube.com/watch?v=\($0)") }
    }
}
