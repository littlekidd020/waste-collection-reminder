import Foundation
import UserNotifications

/// Service for scheduling and managing local push notifications for bin collection reminders.
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // MARK: - Permission

    /// Request notification permission from the user.
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("⚠️ Notification permission error: \(error)")
            return false
        }
    }

    /// Check if notifications are currently authorised.
    func isAuthorised() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Schedule a reminder for a specific bin collection.
    func scheduleReminder(
        binType: BinType,
        collectionDate: Date,
        reminderDate: Date,
        isEvening: Bool
    ) {
        let content = UNMutableNotificationContent()

        if isEvening {
            content.title = "\(binType.icon) \(binType.displayName) bin out tonight!"
            content.body = "Your \(binType.displayName.lowercased()) bin is collected tomorrow."
        } else {
            content.title = "\(binType.icon) \(binType.displayName) day today!"
            content.body = "Don't forget your \(binType.displayName.lowercased()) bin — collection is today."
        }

        content.sound = .default
        content.categoryIdentifier = "BIN_REMINDER"

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let identifier = "\(binType.rawValue)-\(Int(collectionDate.timeIntervalSince1970))-\(isEvening ? "eve" : "morn")"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to schedule notification: \(error)")
            }
        }
    }

    /// Remove all pending notifications.
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Reschedule all upcoming notifications based on the user's zone and preferences.
    func rescheduleUpcoming(zone: CollectionZone, profile: UserProfile) {
        cancelAllReminders()

        let engine = ScheduleEngine()
        let upcoming = engine.upcomingCollections(for: zone, from: Date(), count: 60)

        for collection in upcoming {
            // Evening before
            if profile.notifyEveningBefore {
                guard let eveningBefore = Calendar.current.date(
                    byAdding: .day, value: -1, to: collection.date
                ) else { continue }

                let reminderDate = combineDateAndTime(
                    date: eveningBefore,
                    hour: profile.eveningNotifyHour,
                    minute: profile.eveningNotifyMinute
                )

                // Only schedule future notifications
                if reminderDate > Date() {
                    scheduleReminder(
                        binType: collection.binType,
                        collectionDate: collection.date,
                        reminderDate: reminderDate,
                        isEvening: true
                    )
                }
            }

            // Morning of
            if profile.notifyMorningOf {
                let reminderDate = combineDateAndTime(
                    date: collection.date,
                    hour: profile.morningNotifyHour,
                    minute: profile.morningNotifyMinute
                )

                if reminderDate > Date() {
                    scheduleReminder(
                        binType: collection.binType,
                        collectionDate: collection.date,
                        reminderDate: reminderDate,
                        isEvening: false
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func combineDateAndTime(date: Date, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? date
    }
}
