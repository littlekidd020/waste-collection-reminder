import EventKit
import SwiftData
import UserNotifications
import XCTest
@testable import BinDayNZ

/// Persistence and reminder regressions replace the removed decorative-map component tests.
@MainActor
final class SchedulePersistenceAndReminderTests: XCTestCase {
    private let calendar = ScheduleEngine.collectionCalendar

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func zone(anchor: Date, frequency: Frequency = .weekly, bins: [BinType] = [.rubbish, .recycling, .foodScraps]) -> CollectionZone {
        DataService.shared.manualZone(schedules: bins.map {
            CollectionSchedule(id: $0.rawValue, binType: $0, frequency: frequency, anchorDate: anchor)
        })
    }

    private func preferences(evening: Bool = true, morning: Bool = true, eveningHour: Int = 19, morningHour: Int = 7) -> ReminderPreferences {
        ReminderPreferences(evening: evening, morning: morning, eveningHour: eveningHour,
                            eveningMinute: 0, morningHour: morningHour, morningMinute: 0)
    }

    func testConfirmedScheduleAndChangesSurviveSwiftDataSaveAndFetch() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: UserProfile.self, configurations: configuration)
        let profile = UserProfile()
        profile.zoneId = DataService.manualZoneID
        profile.address = "Public sample location"
        profile.scheduleConfirmedAt = date(2026, 9, 6)
        let savedZone = DataService.shared.manualZone(schedules: [
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 9, 7)),
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .fortnightly, anchorDate: date(2026, 9, 14),
                               changes: [CollectionDateChange(originalDate: date(2026, 9, 28), replacementDate: date(2026, 9, 29))])
        ])
        profile.manualSchedulesJSON = try DataService.shared.encodedManualSchedules(from: savedZone)
        let writingContext = ModelContext(container)
        writingContext.insert(profile)
        try writingContext.save()
        let readingContext = ModelContext(container)
        let fetched = try XCTUnwrap(readingContext.fetch(FetchDescriptor<UserProfile>()).first)
        XCTAssertEqual(try XCTUnwrap(DataService.shared.zone(for: fetched)).schedules, savedZone.schedules)
        XCTAssertEqual(fetched.scheduleConfirmedAt, date(2026, 9, 6))
        XCTAssertEqual(ScheduleEngine().binsCollectedOn(date: date(2026, 9, 29),
                                                       zone: try XCTUnwrap(DataService.shared.zone(for: fetched))), [.recycling])
    }

    func testMissingCorruptLegacyAndInvalidProfilesRequireScheduleConfirmation() throws {
        let profile = UserProfile()
        profile.address = "12 Queen Street, Auckland"
        profile.councilId = "auckland-council"
        profile.zoneId = "akl-dynamic-1-even"
        for json in [
            nil,
            "not-json",
            "[]",
            #"[{"id":"old","binType":"recycling","frequency":"fortnightly","dayOfWeek":1,"weekPattern":"even"}]"#
        ] as [String?] {
            profile.manualSchedulesJSON = json
            XCTAssertNil(DataService.shared.zone(for: profile))
        }
        let schedule = CollectionSchedule(id: "same", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 9, 7))
        profile.manualSchedulesJSON = String(decoding: try JSONEncoder().encode([schedule, schedule]), as: UTF8.self)
        XCTAssertNil(DataService.shared.zone(for: profile))
        XCTAssertThrowsError(try DataService.shared.encodedManualSchedules(from: DataService.shared.manualZone(schedules: [schedule, schedule])))
        XCTAssertThrowsError(try DataService.shared.encodedManualSchedules(from: DataService.shared.manualZone(schedules: [])))
    }

    func testReminderCapacityGroupsAllBinsAndNeverSplitsTheFinalCollectionDay() {
        let value = zone(anchor: date(2026, 9, 7))
        let now = date(2026, 9, 6, hour: 12)
        let plan = NotificationService.plan(zone: value, preferences: preferences(), now: now)
        XCTAssertEqual(plan.count, 60)
        XCTAssertEqual(Set(plan.map(\.id)).count, 60)
        XCTAssertTrue(plan.allSatisfy { Set($0.bins) == [.rubbish, .recycling, .foodScraps] && $0.date > now })
        XCTAssertTrue(Dictionary(grouping: plan, by: \.collectionDate).values.allSatisfy {
            $0.count == 2 && Set($0.map(\.isEvening)) == [true, false]
        })
        let oddLimit = NotificationService.plan(zone: value, preferences: preferences(), now: now, limit: 59)
        XCTAssertEqual(oddLimit.count, 58)
        XCTAssertTrue(Dictionary(grouping: oddLimit, by: \.collectionDate).values.allSatisfy { $0.count == 2 })
        XCTAssertTrue(NotificationService.plan(zone: value, preferences: preferences(), now: now, limit: 1).isEmpty)
        XCTAssertTrue(NotificationService.plan(zone: value, preferences: preferences(), now: now, limit: 0).isEmpty)
        XCTAssertEqual(plan.map(\.id), NotificationService.plan(zone: value, preferences: preferences(), now: now).map(\.id))
    }

    func testReminderPlanUsesMovedDatesAndSkipsOnlyTheAffectedBin() throws {
        let anchor = date(2026, 9, 7)
        let value = DataService.shared.manualZone(schedules: [
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: anchor),
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .weekly, anchorDate: anchor,
                               changes: [CollectionDateChange(originalDate: anchor, replacementDate: date(2026, 9, 8))]),
            CollectionSchedule(id: "food", binType: .foodScraps, frequency: .weekly, anchorDate: anchor,
                               changes: [CollectionDateChange(originalDate: anchor, replacementDate: nil)])
        ])
        let plan = NotificationService.plan(zone: value, preferences: preferences(), now: date(2026, 9, 6, hour: 12))
        XCTAssertEqual(plan.filter { $0.collectionDate == anchor }.map(\.bins), [[.rubbish], [.rubbish]])
        XCTAssertEqual(plan.filter { $0.collectionDate == date(2026, 9, 8) }.map(\.bins), [[.recycling], [.recycling]])
        XCTAssertEqual(Set(try XCTUnwrap(plan.first { $0.collectionDate == date(2026, 9, 14) }).bins), [.rubbish, .recycling, .foodScraps])
    }

    func testNotificationTimesRemainNZWallClockAcrossBothDSTTransitionsAndTravel() {
        let previous = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
        defer { NSTimeZone.default = previous }
        for (collection, elapsedHours) in [(date(2026, 4, 5), 13.0), (date(2026, 9, 27), 11.0)] {
            let now = calendar.date(byAdding: .hour, value: -12, to: collection)!
            let plan = NotificationService.plan(zone: zone(anchor: collection, bins: [.rubbish]),
                                                preferences: preferences(), now: now, limit: 2)
            XCTAssertEqual(plan.count, 2)
            XCTAssertEqual(calendar.component(.hour, from: plan[0].date), 19)
            XCTAssertEqual(calendar.component(.hour, from: plan[1].date), 7)
            XCTAssertEqual(plan[1].date.timeIntervalSince(plan[0].date) / 3600, elapsedHours)
            XCTAssertEqual(plan[0].collectionDate, collection)
            XCTAssertEqual(plan[1].collectionDate, collection)
        }
    }

    func testReminderPlanRejectsInvalidInputsAndOmitsElapsedReminders() {
        let value = zone(anchor: date(2026, 9, 7))
        let now = date(2026, 9, 7, hour: 12)
        let plan = NotificationService.plan(zone: value, preferences: preferences(), now: now)
        XCTAssertTrue(plan.allSatisfy { $0.date > now && $0.collectionDate > calendar.startOfDay(for: now) })
        for invalid in [preferences(eveningHour: -1), preferences(eveningHour: 24), preferences(morningHour: -1), preferences(morningHour: 24),
                        preferences(evening: false, morning: false)] {
            XCTAssertTrue(NotificationService.plan(zone: value, preferences: invalid, now: now).isEmpty)
        }
        let invalidMinute = ReminderPreferences(evening: true, morning: true, eveningHour: 19, eveningMinute: 60, morningHour: 7, morningMinute: 0)
        XCTAssertTrue(NotificationService.plan(zone: value, preferences: invalidMinute, now: now).isEmpty)
        for invalidDate in [Date(timeIntervalSince1970: .nan), Date(timeIntervalSince1970: .infinity)] {
            XCTAssertTrue(NotificationService.plan(zone: value, preferences: preferences(), now: invalidDate).isEmpty)
        }
        let oneMorning = NotificationService.plan(zone: value, preferences: preferences(),
                                                  now: date(2026, 9, 6, hour: 20), limit: 1)
        XCTAssertEqual(oneMorning.count, 1)
        XCTAssertFalse(oneMorning[0].isEvening)
        XCTAssertEqual(oneMorning[0].collectionDate, date(2026, 9, 7))
    }

    func testRemindersCanStartBeyondTheOldSixMonthWindow() {
        let anchor = date(2028, 1, 3)
        let plan = NotificationService.plan(zone: zone(anchor: anchor, frequency: .fortnightly, bins: [.recycling]),
                                            preferences: preferences(), now: date(2026, 9, 6), limit: 4)
        XCTAssertEqual(plan.count, 4)
        XCTAssertEqual(plan.map(\.collectionDate), [anchor, anchor, date(2028, 1, 17), date(2028, 1, 17)])
    }

    #if os(iOS)
    private func waitForInitialAppRefresh() async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(15))
        while !ScheduleCoordinator.shared.hasCheckedAuthorization || ScheduleCoordinator.shared.isUpdating {
            guard clock.now < deadline else {
                throw NSError(domain: "BinDayNZTests.InitialAppRefresh", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "The app coordinator did not finish its initial authorization and refresh within 15 seconds."
                ])
            }
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    func testCoordinatorIgnoresDetachedAndDeletedProfilesWithoutTouchingOutputs() async throws {
        try await waitForInitialAppRefresh()
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: UserProfile.self, configurations: configuration)
        let context = ModelContext(container)
        let coordinator = ScheduleCoordinator()
        let center = UNUserNotificationCenter.current()
        let requestsBefore = await center.pendingNotificationRequests()
        let contentBefore = Dictionary(uniqueKeysWithValues: requestsBefore.map {
            ($0.identifier, [$0.content.title, $0.content.subtitle, $0.content.body])
        })
        let ownershipBefore = UserDefaults.standard.data(forKey: "BinDayNZ.calendarOwnership")
        let widgetDefaults = try XCTUnwrap(UserDefaults(suiteName: WidgetScheduleSnapshot.appGroupID))
        let widgetBefore = widgetDefaults.data(forKey: WidgetScheduleSnapshot.storageKey)
        func assertOutputsUnchanged() async {
            XCTAssertFalse(coordinator.hasCheckedAuthorization)
            XCTAssertFalse(coordinator.isUpdating)
            let requests = await center.pendingNotificationRequests()
            XCTAssertEqual(Dictionary(uniqueKeysWithValues: requests.map {
                ($0.identifier, [$0.content.title, $0.content.subtitle, $0.content.body])
            }), contentBefore)
            XCTAssertEqual(UserDefaults.standard.data(forKey: "BinDayNZ.calendarOwnership"), ownershipBefore)
            XCTAssertEqual(widgetDefaults.data(forKey: WidgetScheduleSnapshot.storageKey), widgetBefore)
        }

        let detached = UserProfile()
        detached.integrationMessage = "Untouched detached profile"
        detached.remindersScheduledThrough = date(2027, 1, 1)
        XCTAssertNil(detached.modelContext)
        await coordinator.refresh(profile: detached, context: context)
        await assertOutputsUnchanged()
        XCTAssertEqual(detached.integrationMessage, "Untouched detached profile")
        XCTAssertEqual(detached.remindersScheduledThrough, date(2027, 1, 1))

        let deleted = UserProfile()
        context.insert(deleted)
        try context.save()
        XCTAssertTrue(deleted.modelContext === context)
        context.delete(deleted)
        XCTAssertTrue(deleted.isDeleted)
        await coordinator.refresh(profile: deleted, context: context)
        await assertOutputsUnchanged()

        try context.save()
        XCTAssertNil(deleted.modelContext)
        await coordinator.refresh(profile: deleted, context: context)
        await assertOutputsUnchanged()
    }
    #endif

    /// Opt in only on a disposable simulator with calendar permission already granted.
    /// Every calendar created and deleted here is synthetic test data.
    func testIsolatedCalendarSyncPreservesUnrelatedEventsAndIsIdempotent() async throws {
        #if targetEnvironment(simulator)
        guard ProcessInfo.processInfo.environment["BINDAYNZ_ISOLATED_CALENDAR_TESTS"] == "1" else {
            throw XCTSkip("Requires an explicitly opted-in disposable simulator.")
        }
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw XCTSkip("Grant Calendar access on the disposable simulator before running.")
        }
        let store = EKEventStore()
        let preexistingCalendarIDs = Set(store.calendars(for: .event).map(\.calendarIdentifier))
        let source = try XCTUnwrap(store.defaultCalendarForNewEvents?.source ?? store.sources.first { $0.sourceType == .local })
        let suiteName = "BinDayNZ.CalendarIsolation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        var createdCalendarIDs: [String] = []
        defer {
            // Recover a calendar created before a failed first sync, but never adopt a preexisting ID.
            if let data = defaults.data(forKey: "BinDayNZ.calendarOwnership"),
               let ownership = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let identifier = ownership["calendarIdentifier"] as? String,
               !preexistingCalendarIDs.contains(identifier) {
                createdCalendarIDs.append(identifier)
            }
            for identifier in Set(createdCalendarIDs) where !preexistingCalendarIDs.contains(identifier) {
                if let calendar = store.calendar(withIdentifier: identifier) {
                    do { try store.removeCalendar(calendar, commit: true) }
                    catch { XCTFail("Could not remove synthetic test calendar: \(error)") }
                }
            }
            defaults.removePersistentDomain(forName: suiteName)
        }
        func syntheticEvent(in calendar: EKCalendar, title: String, date: Date) throws -> String {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = title
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600)
            try store.save(event, span: .thisEvent, commit: true)
            return event.calendarItemIdentifier
        }
        let unrelated = EKCalendar(for: .event, eventStore: store)
        unrelated.title = "Bin Day NZ"
        unrelated.source = source
        try store.saveCalendar(unrelated, commit: true)
        createdCalendarIDs.append(unrelated.calendarIdentifier)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let unrelatedID = try syntheticEvent(in: unrelated, title: "Synthetic personal event", date: tomorrow)
        let service = CalendarService(eventStore: store, defaults: defaults)
        let value = zone(anchor: tomorrow, frequency: .fortnightly, bins: [.recycling])
        try await service.syncToAppleCalendar(zone: value, reminderOffsets: [-18_000.0, 25_200.0])
        let ownershipData = try XCTUnwrap(defaults.data(forKey: "BinDayNZ.calendarOwnership"))
        let ownership = try XCTUnwrap(JSONSerialization.jsonObject(with: ownershipData) as? [String: Any])
        let ownedID = try XCTUnwrap(ownership["calendarIdentifier"] as? String)
        guard !preexistingCalendarIDs.contains(ownedID), ownedID != unrelated.calendarIdentifier else {
            XCTFail("Calendar sync adopted an existing calendar. It must create its own calendar.")
            return
        }
        createdCalendarIDs.append(ownedID)
        let ownedCalendar = try XCTUnwrap(store.calendar(withIdentifier: ownedID))
        let insideUnrelatedID = try syntheticEvent(in: ownedCalendar, title: "Synthetic user-added event", date: tomorrow)
        try await service.syncToAppleCalendar(zone: value, reminderOffsets: [-18_000.0, 25_200.0])
        let current = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(defaults.data(forKey: "BinDayNZ.calendarOwnership"))) as? [String: Any])
        let itemIDs = try XCTUnwrap(current["itemIdentifiers"] as? [String])
        XCTAssertEqual(itemIDs.count, 3)
        let managed = itemIDs.compactMap { store.calendarItem(withIdentifier: $0) as? EKEvent }
        XCTAssertEqual(managed.count, 3)
        XCTAssertTrue(managed.allSatisfy { $0.recurrenceRules?.first?.interval == 2 })
        XCTAssertEqual(managed.filter(\.isAllDay).count, 1)
        XCTAssertEqual(managed.filter { !$0.isAllDay && $0.alarms?.first?.relativeOffset == 0 }.count, 2)
        let predicate = store.predicateForEvents(withStart: tomorrow.addingTimeInterval(-86400),
                                                end: calendar.date(byAdding: .day, value: 60, to: tomorrow)!,
                                                calendars: [ownedCalendar])
        let seriesIDs = Set(store.events(matching: predicate).filter { $0.url?.scheme == "bindaynz" }.map(\.calendarItemIdentifier))
        XCTAssertEqual(seriesIDs.count, 3)
        XCTAssertNotNil(store.calendarItem(withIdentifier: unrelatedID))
        XCTAssertNotNil(store.calendarItem(withIdentifier: insideUnrelatedID))
        try service.removeSyncedCalendar()
        XCTAssertNotNil(store.calendarItem(withIdentifier: unrelatedID))
        XCTAssertNotNil(store.calendarItem(withIdentifier: insideUnrelatedID))
        XCTAssertTrue(store.events(matching: predicate).allSatisfy { $0.url?.scheme != "bindaynz" })
        XCTAssertNoThrow(try service.removeSyncedCalendar())

        // A missing calendar may be temporarily unavailable. Preserve ownership rather than
        // reporting successful cleanup or silently creating a replacement calendar.
        try await service.syncToAppleCalendar(zone: value, reminderOffsets: [-18_000.0, 25_200.0])
        let ownershipBeforeDeletion = try XCTUnwrap(defaults.data(forKey: "BinDayNZ.calendarOwnership"))
        guard createdCalendarIDs.contains(ownedID), !preexistingCalendarIDs.contains(ownedID) else {
            XCTFail("Missing-calendar verification may delete only a known synthetic calendar.")
            return
        }
        try store.removeCalendar(try XCTUnwrap(store.calendar(withIdentifier: ownedID)), commit: true)
        store.reset()
        XCTAssertNil(store.calendar(withIdentifier: ownedID))
        let remainingCalendarIDs = Set(store.calendars(for: .event).map(\.calendarIdentifier))
        XCTAssertThrowsError(try service.removeSyncedCalendar()) { error in
            switch error {
            case CalendarError.calendarUnavailable: break
            default: XCTFail("Expected calendarUnavailable, received \(error)")
            }
        }
        XCTAssertEqual(defaults.data(forKey: "BinDayNZ.calendarOwnership"), ownershipBeforeDeletion)
        XCTAssertEqual(Set(store.calendars(for: .event).map(\.calendarIdentifier)), remainingCalendarIDs)
        do {
            try await service.syncToAppleCalendar(zone: value, reminderOffsets: [-18_000.0, 25_200.0])
            XCTFail("Sync must fail when the saved calendar cannot be opened.")
        } catch CalendarError.calendarUnavailable {
            // Expected: no replacement calendar and no loss of the original ownership record.
        } catch {
            XCTFail("Expected calendarUnavailable, received \(error)")
        }
        XCTAssertEqual(defaults.data(forKey: "BinDayNZ.calendarOwnership"), ownershipBeforeDeletion)
        XCTAssertEqual(Set(store.calendars(for: .event).map(\.calendarIdentifier)), remainingCalendarIDs)
        XCTAssertNotNil(store.calendarItem(withIdentifier: unrelatedID))

        service.forgetConnection()
        XCTAssertNil(defaults.data(forKey: "BinDayNZ.calendarOwnership"))
        XCTAssertEqual(Set(store.calendars(for: .event).map(\.calendarIdentifier)), remainingCalendarIDs)
        XCTAssertNotNil(store.calendarItem(withIdentifier: unrelatedID))
        try await service.syncToAppleCalendar(zone: value)
        let renewed = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(defaults.data(forKey: "BinDayNZ.calendarOwnership"))) as? [String: Any])
        let renewedID = try XCTUnwrap(renewed["calendarIdentifier"] as? String)
        guard !remainingCalendarIDs.contains(renewedID) else {
            XCTFail("Explicit reconnection must create a new calendar without adopting an existing one.")
            return
        }
        createdCalendarIDs.append(renewedID)
        XCTAssertNotEqual(renewedID, ownedID)
        XCTAssertNotNil(store.calendarItem(withIdentifier: unrelatedID))

        // Once cleanup is confirmed, deleting that empty synthetic calendar may be
        // recovered by creating a fresh calendar without abandoning managed events.
        try service.removeSyncedCalendar()
        let cleanOwnership = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(defaults.data(forKey: "BinDayNZ.calendarOwnership"))) as? [String: Any])
        XCTAssertEqual(cleanOwnership["needsCleanup"] as? Bool, false)
        guard createdCalendarIDs.contains(renewedID), !preexistingCalendarIDs.contains(renewedID) else {
            XCTFail("Clean-calendar verification may delete only a known synthetic calendar.")
            return
        }
        try store.removeCalendar(try XCTUnwrap(store.calendar(withIdentifier: renewedID)), commit: true)
        store.reset()
        XCTAssertNil(store.calendar(withIdentifier: renewedID))
        XCTAssertNoThrow(try service.removeSyncedCalendar())
        let calendarsAfterCleanDeletion = Set(store.calendars(for: .event).map(\.calendarIdentifier))
        try await service.syncToAppleCalendar(zone: value)
        let freshOwnership = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(defaults.data(forKey: "BinDayNZ.calendarOwnership"))) as? [String: Any])
        let freshID = try XCTUnwrap(freshOwnership["calendarIdentifier"] as? String)
        guard !calendarsAfterCleanDeletion.contains(freshID), !preexistingCalendarIDs.contains(freshID) else {
            XCTFail("Recovery after confirmed cleanup must create a new calendar.")
            return
        }
        createdCalendarIDs.append(freshID)
        XCTAssertNotEqual(freshID, renewedID)
        XCTAssertNotNil(store.calendarItem(withIdentifier: unrelatedID))
        #else
        throw XCTSkip("This test never accesses a physical device or host user's calendars.")
        #endif
    }

    /// Run only in the same explicitly opted-in disposable simulator as the calendar integration test.
    func testIsolatedNotificationsRetainCompleteBatchAndCancelIt() async throws {
        #if targetEnvironment(simulator)
        guard ProcessInfo.processInfo.environment["BINDAYNZ_ISOLATED_CALENDAR_TESTS"] == "1" else {
            throw XCTSkip("Requires an explicitly opted-in disposable simulator.")
        }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            throw XCTSkip("Grant notifications on the disposable simulator before running.")
        }
        #if os(iOS)
        try await waitForInitialAppRefresh()
        #endif
        let savedRequests = await center.pendingNotificationRequests()
        addTeardownBlock {
            center.removeAllPendingNotificationRequests()
            for request in savedRequests { try await center.add(request) }
        }

        let now = Date()
        let anchor = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))!
        let value = zone(anchor: anchor)
        let options = preferences()
        let expected = NotificationService.plan(zone: value, preferences: options, now: now)
        XCTAssertEqual(expected.count, 60)
        let staleID = "binday.test-stale.\(UUID().uuidString)"
        let staleContent = UNMutableNotificationContent()
        staleContent.title = "Synthetic stale test reminder"
        try await center.add(UNNotificationRequest(identifier: staleID, content: staleContent,
                                                   trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)))

        let horizon = try await NotificationService.shared.rescheduleUpcoming(zone: value, preferences: options, now: now)
        let pending = await center.pendingNotificationRequests()
        let expectedIDs = Set(expected.map(\.id)).union(["binday.renewal"])
        XCTAssertEqual(pending.count, 61)
        XCTAssertEqual(Set(pending.map(\.identifier)), expectedIDs)
        XCTAssertFalse(pending.contains { $0.identifier == staleID })
        XCTAssertEqual(horizon, expected.map(\.collectionDate).max())

        for reminder in expected {
            let request = try XCTUnwrap(pending.first { $0.identifier == reminder.id })
            let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
            XCTAssertFalse(trigger.repeats)
            XCTAssertEqual(trigger.dateComponents.calendar?.identifier, .gregorian)
            XCTAssertEqual(trigger.dateComponents.timeZone?.identifier, "Pacific/Auckland")
            XCTAssertEqual(trigger.nextTriggerDate(), reminder.date)
            XCTAssertEqual(Set(reminder.bins), [.rubbish, .recycling, .foodScraps])
            XCTAssertEqual(request.content.body, reminder.bins.map(\.displayName).joined(separator: ", "))
            XCTAssertNotNil(request.content.sound)
        }
        let renewal = try XCTUnwrap(pending.first { $0.identifier == "binday.renewal" })
        let renewalTrigger = try XCTUnwrap(renewal.trigger as? UNCalendarNotificationTrigger)
        XCTAssertFalse(renewalTrigger.repeats)
        let expectedRenewalDate = calendar.date(byAdding: .day, value: -7, to: try XCTUnwrap(expected.last).date)
        XCTAssertEqual(renewalTrigger.nextTriggerDate(), expectedRenewalDate)
        XCTAssertEqual(renewalTrigger.dateComponents.timeZone?.identifier, "Pacific/Auckland")

        NotificationService.shared.cancelAllReminders()
        let afterCancellation = await center.pendingNotificationRequests()
        XCTAssertTrue(afterCancellation.isEmpty)
        #else
        throw XCTSkip("This test never changes a physical device or host user's notifications.")
        #endif
    }
}
