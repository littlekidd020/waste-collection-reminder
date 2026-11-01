import XCTest
@testable import BinDayNZ

@MainActor
final class CalendarSafetyTests: XCTestCase {
    private let calendar = ScheduleEngine.collectionCalendar

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func zone(anchor: Date, changes: [CollectionDateChange] = []) -> CollectionZone {
        CollectionZone(id: "manual", name: "Manual schedule", suburbs: [], schedules: [
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .fortnightly,
                               anchorDate: anchor, changes: changes)
        ])
    }

    func testOwnershipRequiresBothSavedCalendarAndInstallationMarker() {
        let marker = CalendarService.ownershipMarker(token: "this-install", eventKey: "recycling")
        XCTAssertTrue(CalendarService.ownsEvent(calendarIdentifier: "our-calendar", marker: marker,
                                              ownedCalendarIdentifier: "our-calendar", token: "this-install"))
        for (calendarID, eventMarker, token) in [
            ("unrelated-calendar", marker, "this-install"),
            ("our-calendar", nil, "this-install"),
            ("our-calendar", marker, "other-install"),
            ("our-calendar", CalendarService.ownershipMarker(token: "this-install", eventKey: ""), "this-install")
        ] as [(String, URL?, String)] {
            XCTAssertFalse(CalendarService.ownsEvent(calendarIdentifier: calendarID, marker: eventMarker,
                                                   ownedCalendarIdentifier: "our-calendar", token: token))
        }
        XCTAssertFalse(CalendarService.ownsEvent(calendarIdentifier: nil, marker: marker,
                                               ownedCalendarIdentifier: "our-calendar", token: "this-install"))
    }

    func testNativeSeriesSplitsForMoveAndSkipWithoutChangingFortnightlyCadence() throws {
        let schedule = zone(anchor: date(2026, 12, 14), changes: [
            CollectionDateChange(originalDate: date(2026, 12, 28), replacementDate: date(2026, 12, 29)),
            CollectionDateChange(originalDate: date(2027, 1, 11), replacementDate: nil)
        ])
        let plans = try CalendarService.plannedEvents(zone: schedule)
        XCTAssertEqual(plans.count, 3)
        XCTAssertEqual(plans[0].start, date(2026, 12, 14))
        XCTAssertEqual(plans[0].intervalWeeks, 2)
        XCTAssertEqual(plans[0].recurrenceEnd, date(2026, 12, 28).addingTimeInterval(-1))
        XCTAssertEqual(plans[1].start, date(2026, 12, 29))
        XCTAssertNil(plans[1].intervalWeeks)
        XCTAssertEqual(plans[2].start, date(2027, 1, 25))
        XCTAssertEqual(plans[2].intervalWeeks, 2)
        XCTAssertNil(plans[2].recurrenceEnd)
        XCTAssertTrue(plans.allSatisfy { !$0.isReminder })
    }

    func testCalendarReminderEventsKeepNZClockTimesAcrossDST() throws {
        for (collection, expectedHoursAfterMidnight) in [
            (date(2026, 4, 5), 8.0), (date(2026, 9, 27), 6.0)
        ] {
            let morning = try CalendarService.reminderDate(collectionDate: collection, offset: 7 * 3600)
            let evening = try CalendarService.reminderDate(collectionDate: collection, offset: -5 * 3600)
            XCTAssertEqual(calendar.component(.hour, from: morning), 7)
            XCTAssertEqual(morning.timeIntervalSince(collection) / 3600, expectedHoursAfterMidnight)
            XCTAssertEqual(calendar.component(.hour, from: evening), 19)
            XCTAssertEqual(calendar.dateComponents([.day], from: calendar.startOfDay(for: evening), to: collection).day, 1)
            let plans = try CalendarService.plannedEvents(zone: zone(anchor: collection), reminderOffsets: [-18_000.0, 25_200.0])
            XCTAssertEqual(plans.filter(\.isReminder).map(\.start), [evening, morning])
            XCTAssertTrue(plans.allSatisfy { $0.intervalWeeks == 2 && $0.recurrenceEnd == nil })
        }
    }

    func testSharedValidationRejectsCollisionBeforeProducingCalendarChanges() {
        let schedule = zone(anchor: date(2026, 9, 7), changes: [
            CollectionDateChange(originalDate: date(2026, 9, 7), replacementDate: date(2026, 9, 21))
        ])
        XCTAssertThrowsError(try CalendarService.plannedEvents(zone: schedule))
        XCTAssertThrowsError(try CalendarService.plannedEvents(zone: zone(anchor: date(2026, 9, 7)), reminderOffsets: [.infinity]))
        XCTAssertThrowsError(try CalendarService.plannedEvents(zone: zone(anchor: date(2026, 9, 7)), reminderOffsets: [86400]))
    }

    func testICSHasRequiredFieldsAndIncludesChangedDates() {
        let schedule = zone(anchor: date(2026, 9, 7), changes: [
            CollectionDateChange(originalDate: date(2026, 9, 7), replacementDate: date(2026, 9, 8))
        ])
        let content = CalendarService.icsContent(zone: schedule, from: date(2026, 9, 6))
        XCTAssertTrue(content.contains("DTSTART;VALUE=DATE:20260908\r\n"))
        XCTAssertFalse(content.contains("DTSTART;VALUE=DATE:20260907\r\n"))
        XCTAssertTrue(content.contains("DTEND;VALUE=DATE:20260909\r\n"))
        XCTAssertTrue(content.hasSuffix("END:VCALENDAR\r\n"))
        let events = content.components(separatedBy: "BEGIN:VEVENT\r\n").dropFirst()
        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.allSatisfy { $0.contains("UID:") && $0.contains("DTSTAMP:") })
        XCTAssertFalse(content.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
    }

    func testICSTextEscapingAndUTF8FoldingPreventMalformedContent() {
        XCTAssertEqual(CalendarService.escapeICSText("a,b;c\\d\r\nEND:VEVENT"), "a\\,b\\;c\\\\d\\nEND:VEVENT")
        let line = "DESCRIPTION:" + String(repeating: "♻️回收,", count: 30)
        let folded = CalendarService.foldICSLine(line)
        XCTAssertEqual(folded.replacingOccurrences(of: "\r\n ", with: "", options: .literal), line)
        XCTAssertTrue(folded.components(separatedBy: "\r\n").allSatisfy { $0.utf8.count <= 75 })
    }
}
