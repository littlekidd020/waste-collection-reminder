import XCTest
@testable import BinDayNZ

final class WidgetSnapshotTests: XCTestCase {
    func testOldDateCacheAndInvalidSnapshotsCannotConfigureTheWidget() throws {
        let suite = "BinDayNZ.WidgetSnapshotTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(Data("[]".utf8), forKey: "widgetCollections")
        XCTAssertNil(WidgetScheduleSnapshot.load(from: defaults))
        defaults.set(Data("{}".utf8), forKey: WidgetScheduleSnapshot.storageKey)
        XCTAssertNil(WidgetScheduleSnapshot.load(from: defaults))

        let invalid = WidgetScheduleSnapshot(
            zone: CollectionZone(id: "empty", name: "Empty", suburbs: [], schedules: []),
            languageCode: "en", confirmedAt: date(2026, 9, 6)
        )
        defaults.set(try JSONEncoder().encode(invalid), forKey: WidgetScheduleSnapshot.storageKey)
        XCTAssertNil(WidgetScheduleSnapshot.load(from: defaults))
    }

    func testSnapshotRoundTripPreservesTheConfirmedScheduleAndChangedDate() throws {
        let suite = "BinDayNZ.WidgetSnapshotTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let confirmedAt = date(2026, 9, 6)
        let changedDate = date(2026, 9, 15)
        let zone = CollectionZone(id: "manual", name: "Manual", suburbs: [], schedules: [
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 9, 7), changes: [
                CollectionDateChange(originalDate: date(2026, 9, 14), replacementDate: changedDate)
            ]),
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .fortnightly, anchorDate: date(2026, 9, 7)),
            CollectionSchedule(id: "food", binType: .foodScraps, frequency: .weekly, anchorDate: date(2026, 9, 7))
        ])
        let snapshot = WidgetScheduleSnapshot(zone: zone, languageCode: "mi", confirmedAt: confirmedAt)
        defaults.set(try JSONEncoder().encode(snapshot), forKey: WidgetScheduleSnapshot.storageKey)
        let loaded = try XCTUnwrap(WidgetScheduleSnapshot.load(from: defaults))

        XCTAssertEqual(loaded.languageCode, "mi")
        XCTAssertEqual(loaded.confirmedAt, confirmedAt)
        XCTAssertEqual(loaded.zone, zone)
        let engine = ScheduleEngine()
        XCTAssertEqual(engine.binsCollectedOn(date: date(2026, 9, 14), zone: loaded.zone), [.foodScraps])
        XCTAssertEqual(engine.binsCollectedOn(date: changedDate, zone: loaded.zone), [.rubbish])
        XCTAssertEqual(Set(engine.binsCollectedOn(date: date(2026, 9, 21), zone: loaded.zone)), Set([.rubbish, .recycling, .foodScraps]))
    }

    func testSavedRecurrenceSurvivesDaylightSavingAndHasNoFiniteDateHorizon() throws {
        let anchor = date(2026, 9, 21)
        let snapshot = WidgetScheduleSnapshot(
            zone: CollectionZone(id: "manual", name: "Manual", suburbs: [], schedules: [
                CollectionSchedule(id: "weekly", binType: .rubbish, frequency: .weekly, anchorDate: anchor)
            ]),
            languageCode: "en", confirmedAt: anchor
        )
        let loaded = try JSONDecoder().decode(WidgetScheduleSnapshot.self, from: JSONEncoder().encode(snapshot))
        let engine = ScheduleEngine()
        let acrossDST = engine.upcomingCollections(for: loaded.zone, from: anchor, count: 2)
        XCTAssertEqual(acrossDST.map(\.date), [anchor, date(2026, 9, 28)])
        XCTAssertEqual(acrossDST[1].date.timeIntervalSince(acrossDST[0].date), 7 * 86_400 - 3_600)

        let future = date(2040, 2, 1)
        let collections = engine.upcomingCollections(for: loaded.zone, from: future, count: 8)
        XCTAssertEqual(collections.count, 8)
        XCTAssertTrue(collections.allSatisfy { $0.date >= future && $0.binType == .rubbish })
        for pair in zip(collections, collections.dropFirst()) {
            XCTAssertEqual(ScheduleEngine.collectionCalendar.dateComponents([.day], from: pair.0.date, to: pair.1.date).day, 7)
        }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        ScheduleEngine.collectionCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
