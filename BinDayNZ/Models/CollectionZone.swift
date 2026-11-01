import Foundation

/// A collection zone within a council. Each zone groups suburbs that share
/// the same collection day and schedule.
struct CollectionZone: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let suburbs: [String]
    let schedules: [CollectionSchedule]

    var isValid: Bool {
        !schedules.isEmpty && schedules.allSatisfy(\.isValid)
            && Set(schedules.map(\.binType)).count == schedules.count
    }
}

/// App and widget share recurrence rules, never a finite cache of dates or an address.
struct WidgetScheduleSnapshot: Codable {
    static let appGroupID = "group.com.bindaynz.app"
    static let storageKey = "confirmedWidgetSchedule"
    let zone: CollectionZone
    let languageCode: String
    let confirmedAt: Date?

    static func load(from defaults: UserDefaults) -> WidgetScheduleSnapshot? {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Self.self, from: data), snapshot.zone.isValid else { return nil }
        return snapshot
    }
}
