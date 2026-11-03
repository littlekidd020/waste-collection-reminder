import Foundation

/// Local user-confirmed schedules. Address search never assigns collection dates.
final class DataService {
    static let shared = DataService()
    static let manualZoneID = "manual"
    static let collectionURL = URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/rubbish-recycling-collection-days.html")!
    static let aucklandCouncilID = "auckland-council"
    static let missedCollectionURL = URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/late-missed-collections.html")!
    static let inorganicBookingURL = URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/inorganic-collections/book-inorganic-collection.html")!
    private init() {}

    /// Views read the saved schedule on every body evaluation; decode each JSON value once.
    private let cacheLock = NSLock()
    private var cachedJSON: String?
    private var cachedLanguage: String?
    private var cachedZone: CollectionZone?

    func zone(for profile: UserProfile) -> CollectionZone? {
        guard let json = profile.manualSchedulesJSON else { return nil }
        let language = LanguageManager.shared.currentCode
        cacheLock.lock(); defer { cacheLock.unlock() }
        if json == cachedJSON, language == cachedLanguage { return cachedZone }
        var zone: CollectionZone?
        if let data = json.data(using: .utf8),
           let schedules = try? JSONDecoder().decode([CollectionSchedule].self, from: data) {
            let candidate = manualZone(schedules: schedules)
            zone = candidate.isValid ? candidate : nil
        }
        cachedJSON = json; cachedLanguage = language; cachedZone = zone
        return zone
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
