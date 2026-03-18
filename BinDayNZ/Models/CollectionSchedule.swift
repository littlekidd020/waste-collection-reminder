import Foundation

/// How often a bin type is collected.
enum Frequency: String, Codable {
    case weekly
    case fortnightly
}

/// For fortnightly collections, which week pattern they follow.
enum WeekPattern: String, Codable {
    case odd
    case even
}

/// Defines when a specific bin type is collected within a zone.
struct CollectionSchedule: Codable, Identifiable, Hashable {
    let id: String
    let binType: BinType
    let frequency: Frequency
    /// ISO weekday: 1 = Monday, 2 = Tuesday ... 7 = Sunday
    let dayOfWeek: Int
    /// Only used for fortnightly schedules
    let weekPattern: WeekPattern?
}
