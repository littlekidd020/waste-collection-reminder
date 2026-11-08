import Foundation

/// Council-aware bin guidance. The national material lists live on `BinType` so the widget can
/// share the enum; the council decides which bins exist, where glass goes and which source page
/// backs the guide. Auckland keeps its own reviewed wording and videos.
extension BinType {
    /// Standard bins, in display order, that a guide should show for a council: the council's
    /// kerbside services plus nothing else. Inorganic appears only where it is a council service.
    static func guideBins(for council: Council?) -> [BinType] {
        guard let council else { return [.rubbish, .recycling, .glass, .foodScraps] }
        return allCases.filter { council.services.contains($0) }
    }

    func acceptedItems(for council: Council?) -> [String] {
        guard self == .recycling, let council, council.services.contains(.glass) else { return acceptedItems }
        return acceptedItems.filter { $0 != L("Glass bottles and jars") }
    }

    func rejectedItems(for council: Council?) -> [String] {
        guard self == .recycling, let council, council.services.contains(.glass) else { return rejectedItems }
        return [L("Glass bottles and jars (use your glass bin)")] + rejectedItems
    }

    func guideNotes(for council: Council?) -> [String] {
        guard let council, council != CouncilDirectory.auckland else { return guideNotes }
        switch self {
        case .recycling:
            return [
                L("Empty and rinse containers, then place them loose in your recycling bin."),
                L("Remove all lids and put them in the rubbish."),
                L("Kerbside recycling follows national rules from 2024. Check your council for container sizes and local differences.")
            ]
        case .rubbish:
            return [L("Use your food scraps or organics service where it is available. Check your property's collection instructions for exceptions.")]
        default:
            return guideNotes
        }
    }

    /// The page the guide links as its source: Auckland's bin pages, or the council's rubbish and recycling site.
    func guideSourceURL(for council: Council?) -> URL {
        guard let council, council != CouncilDirectory.auckland else { return aucklandGuideURL }
        return council.website
    }

    /// Council videos exist for Auckland only.
    func youTubeVideoID(for council: Council?) -> String? {
        guard let council, council == CouncilDirectory.auckland else { return nil }
        return youTubeVideoID
    }
}
