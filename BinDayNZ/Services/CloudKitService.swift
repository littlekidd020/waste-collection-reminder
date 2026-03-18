import Foundation
import CloudKit

/// Service for checking and fetching schedule data updates from CloudKit.
/// Uses CloudKit public database to distribute council data updates without
/// requiring a backend server.
final class CloudKitService {

    static let shared = CloudKitService()
    private let container = CKContainer.default()
    private let publicDB: CKDatabase

    private init() {
        publicDB = container.publicCloudDatabase
    }

    // MARK: - Check for Updates

    /// Check if there's a newer version of the council data available.
    /// Returns true if an update is available.
    func checkForUpdates() async -> Bool {
        let currentVersion = DataService.shared.bundledDataVersion()

        do {
            let query = CKQuery(recordType: "CouncilDataVersion", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]

            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)

            for (_, result) in results {
                let record = try result.get()
                if let remoteVersion = record["version"] as? Int {
                    return remoteVersion > currentVersion
                }
            }
        } catch {
            print("⚠️ CloudKit check failed: \(error)")
        }

        return false
    }

    // MARK: - Fetch Updated Data

    /// Fetch the latest council data from CloudKit.
    /// Returns the decoded council data if available.
    func fetchUpdatedData() async -> DataService.CouncilData? {
        do {
            let query = CKQuery(
                recordType: "CouncilDataVersion",
                predicate: NSPredicate(value: true)
            )
            query.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]

            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)

            for (_, result) in results {
                let record = try result.get()

                // The data is stored as a CKAsset (JSON file)
                if let asset = record["dataFile"] as? CKAsset,
                   let fileURL = asset.fileURL {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    let councilData = try decoder.decode(DataService.CouncilData.self, from: data)
                    return councilData
                }
            }
        } catch {
            print("⚠️ CloudKit fetch failed: \(error)")
        }

        return nil
    }

    // MARK: - Save Updated Data Locally

    /// Save fetched data to the app's documents directory for offline use.
    func saveUpdatedData(_ data: DataService.CouncilData) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDir.appendingPathComponent("councils_updated.json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: fileURL)
            print("✅ Updated council data saved locally")
        } catch {
            print("⚠️ Failed to save updated data: \(error)")
        }
    }

    /// Check for updates and apply them if available.
    /// Call this on app launch.
    func checkAndApplyUpdates() async {
        guard await checkForUpdates() else { return }

        if let updatedData = await fetchUpdatedData() {
            saveUpdatedData(updatedData)
        }
    }
}
