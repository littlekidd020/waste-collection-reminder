import XCTest
@testable import BinDayNZ

final class TodayCopyTests: XCTestCase {
    private let calendar = ScheduleEngine.collectionCalendar

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 17) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    override func setUp() {
        super.setUp()
        LanguageManager.shared.apply("en")
    }

    func testPhaseFollowsTheNewZealandDay() {
        let collection = date(2026, 11, 10, hour: 0)
        XCTAssertEqual(TodayCopy.phase(now: date(2026, 11, 9, hour: 17), next: collection), .tonight)
        XCTAssertEqual(TodayCopy.phase(now: date(2026, 11, 9, hour: 6), next: collection), .tonight)
        XCTAssertEqual(TodayCopy.phase(now: date(2026, 11, 10, hour: 6), next: collection), .collectionDay(morning: true))
        XCTAssertEqual(TodayCopy.phase(now: date(2026, 11, 10, hour: 15), next: collection), .collectionDay(morning: false))
        XCTAssertEqual(TodayCopy.phase(now: date(2026, 11, 7, hour: 20), next: collection), .later(days: 3))
        XCTAssertFalse(TodayCopy.Phase.later(days: 3).allowsKerb)
        XCTAssertTrue(TodayCopy.Phase.tonight.allowsKerb)
    }

    func testVerdictsAndSentences() {
        let bins: [BinType] = [.recycling, .rubbish, .foodScraps]
        XCTAssertEqual(TodayCopy.verdict(phase: .tonight, atKerb: false), "Out tonight")
        XCTAssertEqual(TodayCopy.verdict(phase: .tonight, atKerb: true), "Done for tonight")
        XCTAssertEqual(TodayCopy.verdict(phase: .later(days: 4), atKerb: false), "Nothing tonight")
        XCTAssertEqual(TodayCopy.sentence(phase: .tonight, atKerb: false, bins: bins, date: date(2026, 11, 10)),
                       "Recycling, rubbish and food scraps. Put them out tonight.")
        XCTAssertEqual(TodayCopy.sentence(phase: .later(days: 4), atKerb: false, bins: [.rubbish], date: date(2026, 11, 13)),
                       "Next: Rubbish on Friday.")
        XCTAssertEqual(TodayCopy.eyebrow(phase: .tonight, date: date(2026, 11, 10)), "Tomorrow · Tuesday 10 November")
        XCTAssertEqual(TodayCopy.following(date: date(2026, 11, 17), bins: [.rubbish, .foodScraps]),
                       "Then Tuesday 17 November: Rubbish and food scraps.")
    }

    func testListsFollowTheLanguage() {
        XCTAssertEqual(TodayCopy.list([.rubbish]), "Rubbish")
        XCTAssertEqual(TodayCopy.list([.rubbish, .glass]), "Rubbish and glass")
        XCTAssertEqual(TodayCopy.list([.rubbish, .recycling, .glass, .foodScraps]), "Rubbish, recycling, glass and food scraps")
        LanguageManager.shared.apply("mi")
        XCTAssertTrue(TodayCopy.list([.rubbish, .recycling]).contains(" me "))
        LanguageManager.shared.apply("zh-Hans")
        let chinese = TodayCopy.list([.rubbish, .recycling])
        XCTAssertFalse(chinese.contains(" and "))
        XCTAssertTrue(chinese.contains(BinType.rubbish.displayName))
    }

    func testShortAddressPicksTheSuburb() {
        XCTAssertEqual(TodayCopy.shortAddress("14 Valley Road, Mount Eden, Auckland 1024, New Zealand"), "Mount Eden")
        XCTAssertEqual(TodayCopy.shortAddress("5 Queen Street, Auckland 1010"), "Auckland")
        XCTAssertEqual(TodayCopy.shortAddress("Flat 2, 7 Bay Road"), "Bay Road")
        XCTAssertEqual(TodayCopy.shortAddress("Mosgiel"), "Mosgiel")
        XCTAssertNil(TodayCopy.shortAddress(nil))
        XCTAssertNil(TodayCopy.shortAddress(" , "))
    }

    func testDisplayOrderFollowsThePicture() {
        XCTAssertEqual(BinCluster.displayOrder([.rubbish, .recycling, .foodScraps]), [.recycling, .rubbish, .foodScraps])
        XCTAssertEqual(BinCluster.displayOrder([.rubbish, .foodScraps]), [.rubbish, .foodScraps])
        XCTAssertEqual(Set(BinCluster.displayOrder([.rubbish, .recycling, .glass])), [.rubbish, .recycling, .glass])
        XCTAssertGreaterThan(BinCluster.relativeWidth(of: [.rubbish, .recycling, .glass]), BinCluster.relativeWidth(of: [.rubbish]))
    }

    func testBinsAtTheKerbSkipTheirOwnReminders() {
        let collection = date(2026, 11, 10, hour: 0)
        let zone = CollectionZone(id: "manual", name: "Manual", suburbs: [], schedules: [
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: collection)
        ])
        let out = ReminderPreferences(evening: true, morning: true, eveningHour: 19, eveningMinute: 0, morningHour: 7, morningMinute: 0,
                                      bringIn: true, bringInHour: 18, bringInMinute: 0, binsOutOn: collection)
        let plan = NotificationService.plan(zone: zone, preferences: out, now: date(2026, 11, 9, hour: 12), limit: 9)
        let firstDay = plan.filter { calendar.isDate($0.collectionDate, inSameDayAs: collection) }
        XCTAssertEqual(firstDay.map(\.kind), [.bringIn], "only the bring-in reminder survives for bins already out")
        let nextWeek = plan.filter { calendar.isDate($0.collectionDate, inSameDayAs: date(2026, 11, 17)) }
        XCTAssertEqual(Set(nextWeek.map(\.kind)), [.evening, .morning, .bringIn], "later collections keep every reminder")

        let back = ReminderPreferences(evening: true, morning: true, eveningHour: 19, eveningMinute: 0, morningHour: 7, morningMinute: 0)
        let full = NotificationService.plan(zone: zone, preferences: back, now: date(2026, 11, 9, hour: 12), limit: 9)
        XCTAssertEqual(Set(full.filter { calendar.isDate($0.collectionDate, inSameDayAs: collection) }.map(\.kind)), [.evening, .morning])
    }
}
