import Foundation
import UserNotifications

struct ReminderPreferences: Equatable {
    let evening: Bool
    let morning: Bool
    let eveningHour: Int
    let eveningMinute: Int
    let morningHour: Int
    let morningMinute: Int

    var isEnabled: Bool { evening || morning }
    var isValid: Bool {
        (0...23).contains(eveningHour) && (0...59).contains(eveningMinute)
            && (0...23).contains(morningHour) && (0...59).contains(morningMinute)
    }
}

struct PlannedReminder {
    let id: String
    let date: Date
    let collectionDate: Date
    let bins: [BinType]
    let isEvening: Bool
}

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func isAuthorised() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    func cancelAllReminders() { center.removeAllPendingNotificationRequests() }

    /// A conservative bounded batch with a reserved renewal notice. The UI exposes its horizon.
    static func plan(zone: CollectionZone, preferences: ReminderPreferences, now: Date, limit: Int = 60) -> [PlannedReminder] {
        guard now.timeIntervalSince1970.isFinite, zone.isValid, preferences.isEnabled, preferences.isValid, limit > 0 else { return [] }
        let calendar = ScheduleEngine.collectionCalendar
        let collections = ScheduleEngine().upcomingCollections(for: zone, from: now, count: 400)
        let groups = Dictionary(grouping: collections, by: \.date)
        var result: [PlannedReminder] = []
        for date in groups.keys.sorted() {
            let bins = (groups[date] ?? []).map(\.binType)
            var dayReminders: [PlannedReminder] = []
            for evening in [true, false] {
                guard evening ? preferences.evening : preferences.morning else { continue }
                let day = evening ? calendar.date(byAdding: .day, value: -1, to: date)! : date
                let hour = evening ? preferences.eveningHour : preferences.morningHour
                let minute = evening ? preferences.eveningMinute : preferences.morningMinute
                guard let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), fireDate > now else { continue }
                dayReminders.append(PlannedReminder(id: "binday.\(Int(date.timeIntervalSince1970)).\(evening)", date: fireDate, collectionDate: date, bins: bins, isEvening: evening))
            }
            guard result.count + dayReminders.count <= limit else { break }
            result += dayReminders
        }
        return result.sorted { $0.date < $1.date }
    }

    func rescheduleUpcoming(zone: CollectionZone, preferences: ReminderPreferences, now: Date = Date()) async throws -> Date? {
        cancelAllReminders()
        guard preferences.isEnabled else { return nil }
        guard preferences.isValid else { throw ScheduleError.invalid }
        let plan = Self.plan(zone: zone, preferences: preferences, now: now)
        guard let last = plan.last else { throw ScheduleError.invalid }
        do {
            for reminder in plan {
                let names = reminder.bins.map(\.displayName).joined(separator: ", ")
                let content = UNMutableNotificationContent()
                content.title = reminder.isEvening ? L("Bins out tonight") : L("Collection today")
                content.body = names
                content.sound = .default
                try await center.add(request(id: reminder.id, date: reminder.date, content: content))
            }
            let content = UNMutableNotificationContent()
            content.title = L("Refresh your bin reminders")
            content.body = L("Open Bin Day NZ to schedule more reminders and check for collection changes.")
            content.sound = .default
            let renewalDate = max(now.addingTimeInterval(60), ScheduleEngine.collectionCalendar.date(byAdding: .day, value: -7, to: last.date)!)
            try await center.add(request(id: "binday.renewal", date: renewalDate, content: content))
            let pending = await center.pendingNotificationRequests()
            let identifiers = Set(pending.map(\.identifier))
            guard plan.allSatisfy({ identifiers.contains($0.id) }), identifiers.contains("binday.renewal") else {
                throw ReminderError.incomplete
            }
            return plan.map(\.collectionDate).max()
        } catch {
            cancelAllReminders()
            throw error
        }
    }

    private func request(id: String, date: Date, content: UNNotificationContent) -> UNNotificationRequest {
        var components = ScheduleEngine.collectionCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.calendar = ScheduleEngine.collectionCalendar
        components.timeZone = ScheduleEngine.collectionCalendar.timeZone
        return UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
    }
}

enum ReminderError: LocalizedError {
    case incomplete
    var errorDescription: String? { L("Reminders could not all be scheduled. Open the app to try again.") }
}
