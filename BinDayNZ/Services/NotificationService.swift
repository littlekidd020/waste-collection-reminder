import Foundation
import UserNotifications
import os

struct ReminderPreferences: Equatable {
    let evening: Bool
    let morning: Bool
    let eveningHour: Int
    let eveningMinute: Int
    let morningHour: Int
    let morningMinute: Int
    /// An optional afternoon reminder on collection day to bring the bins back in.
    let bringIn: Bool
    let bringInHour: Int
    let bringInMinute: Int
    /// Collections on or before this date get no reminders. The schedule itself is untouched.
    let pausedUntil: Date?
    /// The bins for this collection day are already at the kerb: no evening or morning reminder for it.
    let binsOutOn: Date?

    init(evening: Bool, morning: Bool, eveningHour: Int, eveningMinute: Int, morningHour: Int, morningMinute: Int,
         bringIn: Bool = false, bringInHour: Int = 18, bringInMinute: Int = 0, pausedUntil: Date? = nil, binsOutOn: Date? = nil) {
        self.evening = evening; self.morning = morning
        self.eveningHour = eveningHour; self.eveningMinute = eveningMinute
        self.morningHour = morningHour; self.morningMinute = morningMinute
        self.bringIn = bringIn; self.bringInHour = bringInHour; self.bringInMinute = bringInMinute
        self.pausedUntil = pausedUntil
        self.binsOutOn = binsOutOn
    }

    /// Whether the household has already put this collection's bins out.
    func binsAreOut(on collectionDate: Date) -> Bool {
        guard let binsOutOn else { return false }
        return ScheduleEngine.collectionCalendar.isDate(binsOutOn, inSameDayAs: collectionDate)
    }

    var isEnabled: Bool { evening || morning || bringIn }
    var isValid: Bool {
        (0...23).contains(eveningHour) && (0...59).contains(eveningMinute)
            && (0...23).contains(morningHour) && (0...59).contains(morningMinute)
            && (0...23).contains(bringInHour) && (0...59).contains(bringInMinute)
            && (pausedUntil?.timeIntervalSince1970.isFinite ?? true)
    }

    /// Whether reminders for a collection on this date are silenced by a pause.
    func isPaused(on collectionDate: Date) -> Bool {
        guard let pausedUntil else { return false }
        return collectionDate <= ScheduleEngine.collectionCalendar.startOfDay(for: pausedUntil)
    }
}

enum ReminderKind: String, CaseIterable {
    case evening, morning, bringIn
}

struct PlannedReminder {
    let id: String
    let date: Date
    let collectionDate: Date
    let bins: [BinType]
    let kind: ReminderKind
    var isEvening: Bool { kind == .evening }
}

final class NotificationService {
    static let shared = NotificationService()
    private static let log = Logger(subsystem: "com.bindaynz.app", category: "reminders")
    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func isAuthorised() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    /// Everything, including a snoozed reminder. Used when reminders are turned off.
    func cancelAllReminders() { center.removeAllPendingNotificationRequests() }

    /// The scheduled batch only. A snoozed reminder is one the user asked for from the lock screen;
    /// it is kept until it fires, so opening the app within the hour does not swallow it.
    private func cancelScheduledReminders() async {
        let pending = await center.pendingNotificationRequests().map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { !Self.isSnooze($0) })
    }

    static func isSnooze(_ identifier: String) -> Bool { identifier.hasSuffix(".snooze") }

    /// Snoozing a snoozed reminder reuses its identifier rather than stacking suffixes.
    static func snoozeIdentifier(for identifier: String) -> String {
        isSnooze(identifier) ? identifier : identifier + ".snooze"
    }

    /// A conservative bounded batch with a reserved renewal notice. The UI exposes its horizon.
    /// Each collection date keeps all of its reminders or none, so the batch never ends mid-day.
    static func plan(zone: CollectionZone, preferences: ReminderPreferences, now: Date, limit: Int = 60) -> [PlannedReminder] {
        guard now.timeIntervalSince1970.isFinite, zone.isValid, preferences.isEnabled, preferences.isValid, limit > 0 else { return [] }
        let calendar = ScheduleEngine.collectionCalendar
        let collections = ScheduleEngine().upcomingCollections(for: zone, from: now, count: 400)
        let groups = Dictionary(grouping: collections, by: \.date)
        var result: [PlannedReminder] = []
        for date in groups.keys.sorted() {
            guard !preferences.isPaused(on: date) else { continue }
            let bins = (groups[date] ?? []).map(\.binType)
            let binsOut = preferences.binsAreOut(on: date)
            var dayReminders: [PlannedReminder] = []
            for kind in ReminderKind.allCases {
                // bins already at the kerb need no "put them out" or "collection today" reminder
                if binsOut && kind != .bringIn { continue }
                let enabled: Bool, day: Date, hour: Int, minute: Int
                switch kind {
                case .evening:
                    enabled = preferences.evening; day = calendar.date(byAdding: .day, value: -1, to: date)!
                    hour = preferences.eveningHour; minute = preferences.eveningMinute
                case .morning:
                    enabled = preferences.morning; day = date
                    hour = preferences.morningHour; minute = preferences.morningMinute
                case .bringIn:
                    enabled = preferences.bringIn; day = date
                    hour = preferences.bringInHour; minute = preferences.bringInMinute
                }
                guard enabled else { continue }
                guard let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), fireDate > now else { continue }
                dayReminders.append(PlannedReminder(id: Self.identifier(collectionDate: date, kind: kind), date: fireDate,
                                                    collectionDate: date, bins: bins, kind: kind))
            }
            guard result.count + dayReminders.count <= limit else { break }
            result += dayReminders
        }
        return result.sorted { $0.date < $1.date }
    }

    /// Evening and morning identifiers are unchanged from earlier versions.
    static func identifier(collectionDate: Date, kind: ReminderKind) -> String {
        let stamp = Int(collectionDate.timeIntervalSince1970)
        switch kind {
        case .evening: return "binday.\(stamp).true"
        case .morning: return "binday.\(stamp).false"
        case .bringIn: return "binday.\(stamp).bringIn"
        }
    }

    static func title(for kind: ReminderKind) -> String {
        switch kind {
        case .evening: return L("Bins out tonight")
        case .morning: return L("Collection today")
        case .bringIn: return L("Bring your bins in")
        }
    }

    func rescheduleUpcoming(zone: CollectionZone, preferences: ReminderPreferences, now: Date = Date()) async throws -> Date? {
        await cancelScheduledReminders()
        guard preferences.isEnabled else { return nil }
        guard preferences.isValid else { throw ScheduleError.invalid }
        let plan = Self.plan(zone: zone, preferences: preferences, now: now)
        guard let last = plan.last else { throw ScheduleError.invalid }
        do {
            for reminder in plan {
                let names = reminder.bins.map { "\($0.icon) \($0.displayName)" }.joined(separator: "  ")
                let content = UNMutableNotificationContent()
                content.title = Self.title(for: reminder.kind)
                content.body = names
                content.sound = .default
                content.interruptionLevel = reminder.kind == .bringIn ? .active : .timeSensitive
                content.categoryIdentifier = NotificationRouter.collectionCategory
                content.userInfo = [NotificationRouter.tabKey: 0]
                try await center.add(request(id: reminder.id, date: reminder.date, content: content))
            }
            let content = UNMutableNotificationContent()
            content.title = L("Refresh your bin reminders")
            content.body = L("Open Bin Day NZ to schedule more reminders and check for collection changes.")
            content.sound = .default
            content.userInfo = [NotificationRouter.tabKey: 3]
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

    /// Re-delivers a reminder the user asked to see again. The original has already fired, so its
    /// slot in the pending batch is free; the batch is rebuilt on the next foreground refresh anyway.
    func snooze(_ notification: UNNotification, after interval: TimeInterval = 3600) async {
        let content = notification.request.content.mutableCopy() as? UNMutableNotificationContent ?? UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, interval), repeats: false)
        let id = Self.snoozeIdentifier(for: notification.request.identifier)
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            Self.log.info("Snoozed \(id, privacy: .public) for \(Int(interval))s")
        } catch {
            Self.log.error("Snooze failed for \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func request(id: String, date: Date, content: UNNotificationContent) -> UNNotificationRequest {
        var components = ScheduleEngine.collectionCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.calendar = ScheduleEngine.collectionCalendar
        components.timeZone = ScheduleEngine.collectionCalendar.timeZone
        return UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
    }
}

extension Notification.Name {
    static let binDayOpenTab = Notification.Name("BinDayNZ.openTab")
}

/// Tapping a reminder lands on Today; tapping the renewal notice lands on Settings.
/// Reminders also show as banners while the app is open, and offer Done and Remind me later.
/// Main-actor isolated: UIKit requires the delegate's completion handlers on the main thread, and the
/// async variants call them from whatever executor the method finishes on.
@MainActor
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    static let collectionCategory = "binday.collection"
    static let doneAction = "binday.done"
    static let snoozeAction = "binday.snooze"
    static let tabKey = "tab"

    func install() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.collectionCategory, actions: [
                UNNotificationAction(identifier: Self.doneAction, title: L("Done"), options: []),
                UNNotificationAction(identifier: Self.snoozeAction, title: L("Remind me in 1 hour"), options: [])
            ], intentIdentifiers: [], options: [])
        ])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case Self.snoozeAction:
            await NotificationService.shared.snooze(response.notification)
        case Self.doneAction, UNNotificationDismissActionIdentifier:
            break
        default:
            let tab = response.notification.request.content.userInfo[Self.tabKey] as? Int ?? 0
            NotificationCenter.default.post(name: .binDayOpenTab, object: tab)
        }
    }
}

enum ReminderError: LocalizedError {
    case incomplete
    var errorDescription: String? { L("Reminders could not all be scheduled. Open the app to try again.") }
}
