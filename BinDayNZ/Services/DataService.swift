import Foundation

/// Local user-confirmed schedules. Address search never assigns collection dates.
final class DataService {
    static let shared = DataService()
    static let manualZoneID = "manual"
    static let collectionURL = URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/rubbish-recycling-collection-days.html")!
    static let auckland = Council(id: "auckland-council", name: "Auckland Council", region: "Auckland", binTypes: [.rubbish, .recycling, .foodScraps], zones: [])
    private init() {}

    func council(withId id: String) -> Council? { id == Self.auckland.id ? Self.auckland : nil }

    func zone(for profile: UserProfile) -> CollectionZone? {
        guard let json = profile.manualSchedulesJSON,
              let data = json.data(using: .utf8),
              let schedules = try? JSONDecoder().decode([CollectionSchedule].self, from: data) else { return nil }
        let zone = manualZone(schedules: schedules)
        return zone.isValid ? zone : nil
    }

    func manualZone(schedules: [CollectionSchedule]) -> CollectionZone {
        CollectionZone(id: Self.manualZoneID, name: L("User-confirmed schedule"), suburbs: [], schedules: schedules)
    }

    func encodedManualSchedules(from zone: CollectionZone) throws -> String {
        guard zone.isValid else { throw ScheduleError.invalid }
        return String(decoding: try JSONEncoder().encode(zone.schedules), as: UTF8.self)
    }
}

enum ScheduleError: LocalizedError {
    case invalid
    var errorDescription: String? { L("Check each bin's collection date and frequency before saving.") }
}
