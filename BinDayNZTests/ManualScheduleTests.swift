import XCTest
@testable import BinDayNZ

final class ManualScheduleTests: XCTestCase {
    private let calendar = ScheduleEngine.collectionCalendar
    private let engine = ScheduleEngine()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func zone(_ schedules: [CollectionSchedule]) -> CollectionZone {
        CollectionZone(id: "manual", name: "Confirmed", suburbs: [], schedules: schedules)
    }

    private func schedule(_ bin: BinType = .recycling, frequency: Frequency = .fortnightly,
                          anchor: Date, changes: [CollectionDateChange] = []) -> CollectionSchedule {
        CollectionSchedule(id: bin.rawValue, binType: bin, frequency: frequency, anchorDate: anchor, changes: changes)
    }

    func testEachBinSupportsWeeklyAndFortnightlyWithIndependentDates() {
        for bin in [BinType.rubbish, .recycling, .foodScraps] {
            for frequency in Frequency.allCases {
                let value = schedule(bin, frequency: frequency, anchor: date(2026, 9, 7))
                let collections = engine.upcomingCollections(for: zone([value]), from: date(2026, 9, 6), count: 5)
                XCTAssertEqual(collections.count, 5)
                XCTAssertTrue(collections.allSatisfy { $0.binType == bin })
                XCTAssertEqual(collections[0].date, date(2026, 9, 7))
                XCTAssertEqual(collections[1].date, date(2026, 9, frequency == .weekly ? 14 : 21))
            }
        }
        let mixed = zone([
            schedule(.rubbish, frequency: .weekly, anchor: date(2026, 9, 7)),
            schedule(.recycling, anchor: date(2026, 9, 14)),
            schedule(.foodScraps, frequency: .weekly, anchor: date(2026, 9, 10))
        ])
        XCTAssertEqual(engine.binsCollectedOn(date: date(2026, 9, 7), zone: mixed), [.rubbish])
        XCTAssertEqual(engine.binsCollectedOn(date: date(2026, 9, 10), zone: mixed), [.foodScraps])
        XCTAssertEqual(Set(engine.binsCollectedOn(date: date(2026, 9, 14), zone: mixed)), [.rubbish, .recycling])
        XCTAssertEqual(engine.binsCollectedOn(date: date(2026, 9, 21), zone: mixed), [.rubbish])
    }

    func testFortnightlyDatesStayFourteenDaysApartAcrossBothYearBoundaries() {
        for anchor in [date(2026, 12, 14), date(2026, 12, 21), date(2028, 12, 11), date(2028, 12, 18)] {
            let dates = engine.upcomingCollections(for: zone([schedule(anchor: anchor)]), from: anchor, count: 6).map(\.date)
            XCTAssertEqual(dates.count, 6)
            XCTAssertTrue(zip(dates, dates.dropFirst()).allSatisfy {
                calendar.dateComponents([.day], from: $0, to: $1).day == 14
            })
        }
        XCTAssertEqual(engine.upcomingCollections(for: zone([schedule(anchor: date(2026, 12, 14))]),
                                                  from: date(2026, 12, 14), count: 4).map(\.date),
                       [date(2026, 12, 14), date(2026, 12, 28), date(2027, 1, 11), date(2027, 1, 25)])
    }

    func testNZPropertyDateSurvivesDeviceTimeZoneAndLocaleWeekRules() {
        let previous = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
        defer { NSTimeZone.default = previous }
        let instant = date(2027, 1, 4, hour: 1)
        let value = zone([schedule(anchor: date(2026, 12, 21))])
        XCTAssertEqual(Calendar.current.component(.day, from: instant), 3)
        XCTAssertEqual(ScheduleEngine.collectionCalendar.timeZone.identifier, "Pacific/Auckland")
        XCTAssertEqual(engine.binsCollectedOn(date: instant, zone: value), [.recycling])
        for locale in ["en_NZ", "en_US", "en_GB", "zh_Hans_NZ"] {
            var displayCalendar = Calendar(identifier: .gregorian)
            displayCalendar.locale = Locale(identifier: locale)
            displayCalendar.timeZone = calendar.timeZone
            let sameDate = displayCalendar.date(from: DateComponents(year: 2027, month: 1, day: 4))!
            XCTAssertEqual(engine.binsCollectedOn(date: sameDate, zone: value), [.recycling], locale)
        }
    }

    func testMovesAndSkipsPreserveFutureCadenceAndMonthOutput() {
        let value = zone([schedule(anchor: date(2026, 12, 14), changes: [
            CollectionDateChange(originalDate: date(2026, 12, 28), replacementDate: date(2026, 12, 29)),
            CollectionDateChange(originalDate: date(2027, 1, 11), replacementDate: nil)
        ])])
        XCTAssertTrue(value.isValid)
        XCTAssertEqual(engine.binsCollectedOn(date: date(2026, 12, 28), zone: value), [])
        XCTAssertEqual(engine.binsCollectedOn(date: date(2026, 12, 29), zone: value), [.recycling])
        XCTAssertEqual(engine.binsCollectedOn(date: date(2027, 1, 11), zone: value), [])
        XCTAssertEqual(engine.upcomingCollections(for: value, from: date(2026, 12, 15), count: 3).map(\.date),
                       [date(2026, 12, 29), date(2027, 1, 25), date(2027, 2, 8)])
        XCTAssertEqual(engine.collectionsForMonth(year: 2027, month: 1, zone: value), [25: [.recycling]])
    }

    func testCollisionsAreRejectedButAnExplicitlyVacatedDateAndNoOpAreValid() {
        let anchor = date(2026, 9, 7)
        let collision = schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: anchor, replacementDate: date(2026, 9, 21))
        ])
        XCTAssertFalse(collision.isValid)
        let duplicateReplacement = schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: anchor, replacementDate: date(2026, 9, 8)),
            CollectionDateChange(originalDate: date(2026, 9, 21), replacementDate: date(2026, 9, 8))
        ])
        XCTAssertFalse(duplicateReplacement.isValid)
        let duplicateOriginal = schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: anchor, replacementDate: nil),
            CollectionDateChange(originalDate: anchor, replacementDate: date(2026, 9, 8))
        ])
        XCTAssertFalse(duplicateOriginal.isValid)
        let vacated = zone([schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: anchor, replacementDate: date(2026, 9, 21)),
            CollectionDateChange(originalDate: date(2026, 9, 21), replacementDate: nil)
        ])])
        XCTAssertTrue(vacated.isValid)
        XCTAssertEqual(engine.upcomingCollections(for: vacated, from: anchor, count: 2).map(\.date),
                       [date(2026, 9, 21), date(2026, 10, 5)])
        let noOp = zone([schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: anchor, replacementDate: anchor)
        ])])
        XCTAssertTrue(noOp.isValid)
        XCTAssertEqual(engine.upcomingCollections(for: noOp, from: anchor, count: 2).map(\.date),
                       [anchor, date(2026, 9, 21)])
    }

    func testInvalidAndNonfiniteDatesNeverBecomeCollections() {
        let anchor = date(2026, 9, 7)
        for invalid in [Date(timeIntervalSince1970: .nan), Date(timeIntervalSince1970: .infinity), Date(timeIntervalSince1970: -.infinity)] {
            for value in [
                schedule(anchor: invalid),
                schedule(anchor: anchor, changes: [CollectionDateChange(originalDate: invalid, replacementDate: nil)]),
                schedule(anchor: anchor, changes: [CollectionDateChange(originalDate: anchor, replacementDate: invalid)])
            ] {
                XCTAssertFalse(value.isValid)
                XCTAssertEqual(engine.upcomingCollections(for: zone([value]), from: anchor, count: 2), [])
            }
            let validZone = zone([schedule(anchor: anchor)])
            XCTAssertEqual(engine.binsCollectedOn(date: invalid, zone: validZone), [])
            XCTAssertEqual(engine.upcomingCollections(for: validZone, from: invalid, count: 2), [])
        }
        XCTAssertFalse(schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: date(2026, 9, 8), replacementDate: nil)
        ]).isValid)
        XCTAssertFalse(schedule(anchor: anchor, changes: [
            CollectionDateChange(originalDate: anchor, replacementDate: date(2026, 9, 6))
        ]).isValid)
        XCTAssertFalse(zone([]).isValid)
        XCTAssertFalse(zone([schedule(anchor: anchor), schedule(anchor: anchor)]).isValid)
        XCTAssertFalse(schedule(.inorganic, anchor: anchor).isValid)
    }

    func testWeeklyDatesPreserveMidnightThroughNZDST() {
        for (anchor, elapsedHours) in [(date(2026, 3, 30), 169.0), (date(2026, 9, 21), 167.0)] {
            let dates = engine.upcomingCollections(for: zone([schedule(.rubbish, frequency: .weekly, anchor: anchor)]),
                                                   from: anchor, count: 2).map(\.date)
            XCTAssertEqual(calendar.dateComponents([.day], from: dates[0], to: dates[1]).day, 7)
            XCTAssertEqual(dates[1].timeIntervalSince(dates[0]) / 3600, elapsedHours)
            XCTAssertTrue(dates.allSatisfy { calendar.component(.hour, from: $0) == 0 })
        }
    }

    func testSchedulesDoNotExpireAtAnArbitraryLookaheadOrBeforeTheirAnchor() {
        let anchor = date(2028, 1, 3)
        let value = zone([schedule(anchor: anchor)])
        XCTAssertEqual(engine.upcomingCollections(for: value, from: date(2026, 9, 6), count: 2).map(\.date),
                       [anchor, date(2028, 1, 17)])
        XCTAssertEqual(engine.binsCollectedOn(date: date(2027, 12, 20), zone: value), [])
        let future = engine.upcomingCollections(for: value, from: date(2050, 1, 1), count: 6)
        XCTAssertEqual(future.count, 6)
        XCTAssertTrue(future.allSatisfy { $0.date >= date(2050, 1, 1) })
        XCTAssertTrue(zip(future, future.dropFirst()).allSatisfy {
            calendar.dateComponents([.day], from: $0.date, to: $1.date).day == 14
        })
        XCTAssertEqual(engine.upcomingCollections(for: value, from: anchor, count: 0), [])
        XCTAssertEqual(engine.upcomingCollections(for: value, from: anchor, count: -1), [])
    }
}
