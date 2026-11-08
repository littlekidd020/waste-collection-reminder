import XCTest
@testable import BinDayNZ

final class ShareAndHolidayTests: XCTestCase {
    private let calendar = ScheduleEngine.collectionCalendar

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func zone(_ schedules: [CollectionSchedule]) -> CollectionZone {
        DataService.shared.manualZone(schedules: schedules)
    }

    func testScheduleLinkRoundTripsRegularCyclesAndRejectsBadInput() throws {
        let original = zone([
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 11, 6)),
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .fortnightly, anchorDate: date(2026, 11, 13),
                               changes: [CollectionDateChange(originalDate: date(2026, 11, 27), replacementDate: nil)])
        ])
        let url = try XCTUnwrap(ScheduleLink.url(for: original, council: CouncilDirectory.council(id: "dunedin-city-council")))
        XCTAssertEqual(url.scheme, "bindaynz")
        XCTAssertEqual(ScheduleLink.council(from: url)?.id, "dunedin-city-council")
        XCTAssertNil(ScheduleLink.council(from: try XCTUnwrap(ScheduleLink.url(for: original))), "No council in the link, none invented")
        XCTAssertNil(ScheduleLink.council(from: URL(string: "bindaynz://schedule?v=1&c=nowhere&b=rubbish.w.20261106")!))
        let decoded = try XCTUnwrap(ScheduleLink.zone(from: url))
        XCTAssertEqual(decoded.schedules.map(\.binType), [.rubbish, .recycling])
        XCTAssertEqual(decoded.schedules.map(\.frequency), [.weekly, .fortnightly])
        XCTAssertEqual(decoded.schedules.map(\.anchorDate), [date(2026, 11, 6), date(2026, 11, 13)])
        XCTAssertTrue(decoded.schedules.allSatisfy { $0.changes.isEmpty }, "One-off changes are property specific and must not travel")
        for bad in ["bindaynz://schedule?v=1&b=rubbish.x.20261106", "bindaynz://schedule?v=9&b=rubbish.w.20261106",
                    "bindaynz://schedule?v=1&b=inorganic.w.20261106", "bindaynz://schedule?v=1", "https://example.com/?b=rubbish.w.20261106"] {
            XCTAssertNil(ScheduleLink.zone(from: URL(string: bad)!), bad)
        }
    }

    func testFridayHolidayMovesOnlyThatFridayToSaturday() throws {
        let value = zone([
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 11, 6)), // Fridays
            CollectionSchedule(id: "food", binType: .foodScraps, frequency: .weekly, anchorDate: date(2026, 11, 5))   // Thursdays
        ])
        let suggestions = HolidayShiftService.suggestions(for: value, council: CouncilDirectory.auckland, now: date(2026, 12, 10))
        let christmas = try XCTUnwrap(suggestions.first { $0.holiday.id == "christmas-2026" })
        XCTAssertEqual(christmas.moves.map(\.binType), [.rubbish])
        XCTAssertEqual(christmas.moves.first?.original, date(2026, 12, 25))
        XCTAssertEqual(christmas.moves.first?.replacement, date(2026, 12, 26))
        XCTAssertFalse(suggestions.contains { $0.holiday.id == "new-year-2027" }, "Outside the 21-day lead window")
        let applied = try XCTUnwrap(HolidayShiftService.applying(christmas, to: value))
        XCTAssertEqual(ScheduleEngine().binsCollectedOn(date: date(2026, 12, 25), zone: applied), [])
        XCTAssertEqual(ScheduleEngine().binsCollectedOn(date: date(2026, 12, 26), zone: applied), [.rubbish])
        XCTAssertEqual(ScheduleEngine().binsCollectedOn(date: date(2026, 12, 24), zone: applied), [.foodScraps])
    }

    func testMondayHolidayShiftsTheWholeWeekAndSkipsAlreadyChangedDates() throws {
        let value = zone([
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 11, 2)),   // Mondays
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .fortnightly, anchorDate: date(2026, 11, 4), // Wednesdays
                               changes: [CollectionDateChange(originalDate: date(2027, 1, 6), replacementDate: date(2027, 1, 7))])
        ])
        let suggestions = HolidayShiftService.suggestions(for: value, council: CouncilDirectory.auckland, now: date(2027, 1, 2))
        let dayAfter = try XCTUnwrap(suggestions.first { $0.holiday.id == "day-after-new-year-2027" })
        XCTAssertEqual(dayAfter.moves.map(\.original), [date(2027, 1, 4)], "Recycling on 6 Jan was already changed by the user")
        XCTAssertEqual(dayAfter.moves.first?.replacement, date(2027, 1, 5))
        XCTAssertTrue(HolidayShiftService.suggestions(for: value, council: CouncilDirectory.auckland, now: date(2027, 1, 2), dismissed: ["day-after-new-year-2027"]).isEmpty)
        let later = HolidayShiftService.suggestions(for: value, council: CouncilDirectory.auckland, now: date(2027, 1, 11))
        XCTAssertFalse(later.contains { $0.holiday.id == "day-after-new-year-2027" }, "The holiday week has passed")
        XCTAssertEqual(later.map(\.holiday.id), ["auckland-anniversary-2027"], "Anniversary Day enters the 21-day window on 11 January")
    }

    func testOtherCouncilsSeeTheirOwnAnniversaryAndOnlyAProposal() throws {
        let wellington = try XCTUnwrap(CouncilDirectory.council(id: "wellington-city-council"))
        let value = zone([CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 11, 2))]) // Mondays
        let suggestions = HolidayShiftService.suggestions(for: value, council: wellington, now: date(2027, 1, 11))
        XCTAssertEqual(suggestions.map(\.holiday.id), ["wellington-anniversary-2027"], "Wellington's day, not Auckland's")
        let suggestion = try XCTUnwrap(suggestions.first)
        XCTAssertFalse(suggestion.policy.appliesAutomatically)
        XCTAssertEqual(suggestion.policy.sourceURL, wellington.collectionDayURL)
        XCTAssertEqual(suggestion.moves.map(\.original), [date(2027, 1, 25)])
        XCTAssertNil(HolidayShiftService.applying(suggestion, to: value), "An unverified rule is never written into the schedule")
        let christchurch = try XCTUnwrap(CouncilDirectory.council(id: "christchurch-city-council"))
        XCTAssertEqual(PublicHoliday.holidays(for: christchurch).filter { $0.anniversary != nil }.map(\.id), ["canterbury-anniversary-2027"])
        XCTAssertEqual(PublicHoliday.holidays(for: CouncilDirectory.auckland).count, PublicHoliday.season2026_27.filter { $0.anniversary == nil }.count + 1)
    }
}
