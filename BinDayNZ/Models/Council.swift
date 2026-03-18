import Foundation

/// Represents a territorial authority / council in New Zealand.
/// Each council has its own bin types and collection zones.
struct Council: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let region: String
    let binTypes: [BinType]
    let zones: [CollectionZone]

    static func == (lhs: Council, rhs: Council) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
