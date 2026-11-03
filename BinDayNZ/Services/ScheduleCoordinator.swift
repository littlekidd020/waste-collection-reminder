import Foundation
import SwiftData
import CoreLocation
import Observation

/// One saved schedule drives every output; optional integration failures never masquerade as save failures.
@MainActor @Observable
final class ScheduleCoordinator {
    static let shared = ScheduleCoordinator()
    private(set) var isUpdating = false
    private(set) var notificationsAuthorized = false
    private(set) var hasCheckedAuthorization = false
    private var refreshAgain = false

    func save(zone: CollectionZone, address: String?, coordinate: CLLocationCoordinate2D?, profile: UserProfile, context: ModelContext) async throws {
        let json = try DataService.shared.encodedManualSchedules(from: zone)
        profile.manualSchedulesJSON = json
        profile.zoneId = DataService.manualZoneID
        profile.councilId = DataService.aucklandCouncilID
        profile.address = address?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        profile.latitude = coordinate?.latitude
        profile.longitude = coordinate?.longitude
        profile.scheduleConfirmedAt = Date()
        profile.hasCompletedOnboarding = true
        do { try context.save() } catch { context.rollback(); throw error }
        await refresh(profile: profile, context: context)
    }

    func refresh(profile: UserProfile, context: ModelContext) async {
        guard profile.modelContext === context, !profile.isDeleted else { return }
        if isUpdating { refreshAgain = true; return }
        isUpdating = true
        defer { isUpdating = false }
        repeat {
            refreshAgain = false
            guard profile.modelContext === context, !profile.isDeleted else { return }
            await refreshOutputs(profile: profile, context: context)
        } while refreshAgain
    }

    private func refreshOutputs(profile: UserProfile, context: ModelContext) async {
        var messages: [String] = []
        notificationsAuthorized = await NotificationService.shared.isAuthorised()
        hasCheckedAuthorization = true
        guard let zone = DataService.shared.zone(for: profile) else {
            NotificationService.shared.cancelAllReminders()
            WidgetDataService.clear()
            profile.remindersScheduledThrough = nil
            do {
                try CalendarService.shared.removeSyncedCalendar()
                profile.integrationMessage = nil
            } catch {
                profile.integrationMessage = L("Calendar needs attention: %@", error.localizedDescription)
            }
            try? context.save()
            return
        }
        if let pausedUntil = profile.remindersPausedUntil,
           pausedUntil < ScheduleEngine.collectionCalendar.startOfDay(for: Date()) {
            profile.remindersPausedUntil = nil
        }
        let preferences = profile.reminderPreferences
        do { try WidgetDataService.update(zone: zone, profile: profile) }
        catch { messages.append(L("Your schedule saved, but the widget could not update. Try again.")) }
        profile.remindersScheduledThrough = nil
        if preferences.isEnabled && notificationsAuthorized {
            do {
                profile.remindersScheduledThrough = try await NotificationService.shared.rescheduleUpcoming(zone: zone, preferences: preferences)
            } catch { messages.append(L("Your schedule saved. Reminders need attention: %@", error.localizedDescription)) }
        } else {
            NotificationService.shared.cancelAllReminders()
        }
        do {
            if profile.calendarSyncEnabled {
                let offsets = profile.calendarRemindersEnabled ? profile.calendarReminderOffsets : []
                try await CalendarService.shared.syncToAppleCalendar(zone: zone, reminderOffsets: offsets)
            } else {
                try CalendarService.shared.removeSyncedCalendar()
            }
        } catch {
            messages.append(L("Your schedule saved. Calendar needs attention: %@", error.localizedDescription))
        }
        profile.integrationMessage = messages.isEmpty ? nil : messages.joined(separator: "\n")
        do { try context.save() }
        catch { profile.integrationMessage = L("The latest reminder status could not be saved. Open the app to try again.") }
    }
}

extension UserProfile {
    var reminderPreferences: ReminderPreferences {
        ReminderPreferences(evening: notifyEveningBefore, morning: notifyMorningOf, eveningHour: eveningNotifyHour, eveningMinute: eveningNotifyMinute,
                            morningHour: morningNotifyHour, morningMinute: morningNotifyMinute,
                            bringIn: notifyBringIn, bringInHour: bringInNotifyHour, bringInMinute: bringInNotifyMinute,
                            pausedUntil: remindersPausedUntil)
    }
    var calendarReminderOffsets: [TimeInterval] {
        // Calendar reminders remain independently useful when local reminders are switched off.
        [TimeInterval((eveningNotifyHour - 24) * 3600 + eveningNotifyMinute * 60), TimeInterval(morningNotifyHour * 3600 + morningNotifyMinute * 60)]
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
