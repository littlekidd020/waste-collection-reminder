import Foundation
import WidgetKit

enum WidgetDataService {
    static func update(zone: CollectionZone, profile: UserProfile) throws {
        let snapshot = WidgetScheduleSnapshot(zone: zone, languageCode: profile.languageCode, confirmedAt: profile.scheduleConfirmedAt)
        let data = try JSONEncoder().encode(snapshot)
        guard let defaults = UserDefaults(suiteName: WidgetScheduleSnapshot.appGroupID) else { throw ScheduleError.invalid }
        defaults.set(data, forKey: WidgetScheduleSnapshot.storageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clear() {
        UserDefaults(suiteName: WidgetScheduleSnapshot.appGroupID)?.removeObject(forKey: WidgetScheduleSnapshot.storageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
