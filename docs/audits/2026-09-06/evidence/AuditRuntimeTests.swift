import XCTest
import EventKit
import UserNotifications
@testable import BinDayNZ

// Audit-only tests, appended to the existing test file in an isolated copy.
// The calendar test must run only on the dedicated disposable audit simulator.
final class AuditRuntimeTests: XCTestCase {
    func testPendingReminderHorizon() async throws {
        let zone = DataService.shared.manualZone(schedules: [BinType.rubbish, .recycling, .foodScraps].map {
            CollectionSchedule(id: "audit-\($0.rawValue)", binType: $0, frequency: .weekly, dayOfWeek: 1, weekPattern: nil)
        })
        let profile = UserProfile()
        profile.notifyEveningBefore = true
        profile.notifyMorningOf = true
        NotificationService.shared.rescheduleUpcoming(zone: zone, profile: profile)
        try await Task.sleep(for: .seconds(4))
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let dates = requests.compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }.sorted()
        print("AUDIT_PENDING count=\(requests.count) first=\(String(describing: dates.first)) last=\(String(describing: dates.last))")
        print("AUDIT_PENDING_SETTINGS \(await UNUserNotificationCenter.current().notificationSettings())")
        XCTAssertFalse(requests.isEmpty)
    }

    func testCalendarTitleCollisionPreservesUnrelatedEvent() async throws {
        let store = EKEventStore()
        guard try await store.requestFullAccessToEvents() else { throw XCTSkip("Calendar permission unavailable") }
        guard let source = store.defaultCalendarForNewEvents?.source ?? store.sources.first(where: { $0.sourceType == .local }) else {
            throw XCTSkip("No writable calendar source in isolated simulator")
        }
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Bin Day NZ"
        calendar.source = source
        try store.saveCalendar(calendar, commit: true)
        let event = EKEvent(eventStore: store)
        event.title = "AUDIT unrelated synthetic appointment"
        event.calendar = calendar
        event.startDate = Date().addingTimeInterval(3 * 86400)
        event.endDate = event.startDate.addingTimeInterval(3600)
        try store.save(event, span: .thisEvent)
        let identifier = try XCTUnwrap(event.eventIdentifier)
        let zone = DataService.shared.manualZone(schedules: [CollectionSchedule(id: "audit-rubbish", binType: .rubbish, frequency: .weekly, dayOfWeek: 1, weekPattern: nil)])
        try await CalendarService.shared.syncToAppleCalendar(zone: zone)
        store.refreshSourcesIfNecessary()
        let survivor = store.event(withIdentifier: identifier)
        print("AUDIT_CALENDAR unrelatedEventSurvived=\(survivor != nil)")
        XCTAssertNotNil(survivor, "Calendar sync deleted a synthetic unrelated appointment in a same-title calendar")
    }
}
