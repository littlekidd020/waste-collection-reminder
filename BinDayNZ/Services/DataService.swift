import Foundation

/// Service for loading and querying council/zone data.
final class DataService {

    struct CouncilData: Codable {
        let version: Int
        let councils: [Council]
    }

    // MARK: - Singleton

    static let shared = DataService()
    private var cachedData: CouncilData?

    private init() {}

    // MARK: - Loading

    /// Load councils from the bundled JSON file.
    func loadBundledCouncils() -> [Council] {
        if let cached = cachedData {
            return cached.councils
        }

        guard let url = Bundle.main.url(forResource: "councils", withExtension: "json") else {
            print("⚠️ councils.json not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let councilData = try decoder.decode(CouncilData.self, from: data)
            self.cachedData = councilData
            return councilData.councils
        } catch {
            print("⚠️ Failed to decode councils.json: \(error)")
            return []
        }
    }

    /// Get the bundled data version number.
    func bundledDataVersion() -> Int {
        if let cached = cachedData {
            return cached.version
        }
        _ = loadBundledCouncils()
        return cachedData?.version ?? 0
    }

    // MARK: - Querying

    /// Find a council by its ID.
    func council(withId id: String) -> Council? {
        return loadBundledCouncils().first { $0.id == id }
    }

    /// Find a zone within a council by its ID.
    func zone(withId zoneId: String, in councilId: String) -> CollectionZone? {
        guard let council = council(withId: councilId) else { return nil }
        return council.zones.first { $0.id == zoneId }
    }

    /// Find the zone that serves a given suburb within a council.
    func findZone(for suburb: String, in council: Council) -> CollectionZone? {
        return council.zones.first { zone in
            zone.suburbs.contains { $0.localizedCaseInsensitiveCompare(suburb) == .orderedSame }
        }
    }

    /// Find the zone that serves a given suburb across all supported councils.
    func zoneForSuburb(_ suburb: String) -> CollectionZone? {
        for council in supportedCouncils() {
            if let zone = findZone(for: suburb, in: council) {
                return zone
            }
        }
        return nil
    }

    /// Get all suburbs for a council, sorted alphabetically.
    func allSuburbs(for council: Council) -> [String] {
        return council.zones.flatMap { $0.suburbs }.sorted()
    }

    /// Get all supported councils (those with zone data).
    func supportedCouncils() -> [Council] {
        return loadBundledCouncils().filter { !$0.zones.isEmpty }
    }

    /// Get all councils including unsupported ones (for "coming soon" display).
    func allCouncils() -> [Council] {
        return loadBundledCouncils()
    }

    /// Search suburbs matching a query string within a council.
    func searchSuburbs(query: String, in council: Council) -> [String] {
        guard !query.isEmpty else { return allSuburbs(for: council) }
        return allSuburbs(for: council).filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }
}
