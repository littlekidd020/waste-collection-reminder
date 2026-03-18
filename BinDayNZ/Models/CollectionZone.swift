import Foundation

/// A collection zone within a council. Each zone groups suburbs that share
/// the same collection day and schedule.
struct CollectionZone: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let suburbs: [String]
    let schedules: [CollectionSchedule]

    static func == (lhs: CollectionZone, rhs: CollectionZone) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
