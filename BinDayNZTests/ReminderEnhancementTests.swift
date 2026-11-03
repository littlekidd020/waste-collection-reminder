import XCTest
@testable import BinDayNZ

/// Bring-in reminders, the away pause, notification actions and the plain-language share text.
final class ReminderEnhancementTests: XCTestCase {
    private let calendar = ScheduleEngine.collectionCalendar

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func zone(_ schedules: [CollectionSchedule]) -> CollectionZone {
        DataService.shared.manualZone(schedules: schedules)
    }

    private var weeklyTuesdays: CollectionZone {
        zone([CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 11, 3)),
              CollectionSchedule(id: "food", binType: .foodScraps, frequency: .weekly, anchorDate: date(2026, 11, 3))])
    }

    private func preferences(bringIn: Bool = false, pausedUntil: Date? = nil) -> ReminderPreferences {
        ReminderPreferences(evening: true, morning: true, eveningHour: 19, eveningMinute: 0, morningHour: 7, morningMinute: 0,
                            bringIn: bringIn, bringInHour: 18, bringInMinute: 30, pausedUntil: pausedUntil)
    }

    func testBringInReminderIsOffByDefaultAndAddsOneAfternoonAlertPerCollectionDay() {
        let now = date(2026, 11, 1, hour: 12)
        let plain = NotificationService.plan(zone: weeklyTuesdays, preferences: preferences(), now: now)
        XCTAssertEqual(plain.count, 60)
        XCTAssertFalse(plain.contains { $0.kind == .bringIn })

        let withBringIn = NotificationService.plan(zone: weeklyTuesdays, preferences: preferences(bringIn: true), now: now)
        XCTAssertEqual(withBringIn.count, 60, "Three reminders per date still fill the batch exactly")
        let byDate = Dictionary(grouping: withBringIn, by: \.collectionDate)
        XCTAssertEqual(byDate.count, 20, "The horizon shortens from 30 to 20 collection dates")
        for (collectionDate, reminders) in byDate {
            XCTAssertEqual(Set(reminders.map(\.kind)), [.evening, .morning, .bringIn])
            let bringIn = reminders.first { $0.kind == .bringIn }!
            XCTAssertTrue(calendar.isDate(bringIn.date, inSameDayAs: collectionDate))
            XCTAssertEqual(calendar.component(.hour, from: bringIn.date), 18)
            XCTAssertEqual(calendar.component(.minute, from: bringIn.date), 30)
            XCTAssertEqual(bringIn.id, "binday.\(Int(collectionDate.timeIntervalSince1970)).bringIn")
            XCTAssertEqual(Set(bringIn.bins), [.rubbish, .foodScraps])
        }
        XCTAssertEqual(withBringIn.map(\.date), withBringIn.map(\.date).sorted())
    }

    func testBringInAloneIsEnoughToEnableRemindersAndInvalidTimesAreRejected() {
        let only = ReminderPreferences(evening: false, morning: false, eveningHour: 19, eveningMinute: 0, morningHour: 7, morningMinute: 0, bringIn: true)
        XCTAssertTrue(only.isEnabled)
        let plan = NotificationService.plan(zone: weeklyTuesdays, preferences: only, now: date(2026, 11, 1), limit: 4)
        XCTAssertEqual(plan.map(\.kind), [.bringIn, .bringIn, .bringIn, .bringIn])
        let bad = ReminderPreferences(evening: true, morning: true, eveningHour: 19, eveningMinute: 0, morningHour: 7, morningMinute: 0, bringIn: true, bringInHour: 24)
        XCTAssertFalse(bad.isValid)
        XCTAssertTrue(NotificationService.plan(zone: weeklyTuesdays, preferences: bad, now: date(2026, 11, 1)).isEmpty)
    }

    func testEveningAndMorningIdentifiersAreUnchangedFromEarlierVersions() {
        let plan = NotificationService.plan(zone: weeklyTuesdays, preferences: preferences(), now: date(2026, 11, 1), limit: 2)
        let stamp = Int(date(2026, 11, 3).timeIntervalSince1970)
        XCTAssertEqual(plan.map(\.id), ["binday.\(stamp).true", "binday.\(stamp).false"])
        XCTAssertEqual(plan.map(\.isEvening), [true, false])
    }

    func testPauseSilencesCollectionsThroughTheChosenDayOnlyAndLeavesTheScheduleAlone() {
        let now = date(2026, 11, 1, hour: 12)
        let paused = NotificationService.plan(zone: weeklyTuesdays, preferences: preferences(pausedUntil: date(2026, 11, 17, hour: 15)), now: now)
        XCTAssertEqual(paused.count, 60, "A pause frees batch slots for later collections")
        let first = paused.map(\.collectionDate).min()
        XCTAssertEqual(first, date(2026, 11, 24), "3, 10 and 17 November are paused; the 17th is inclusive whatever the time")
        XCTAssertEqual(ScheduleEngine().binsCollectedOn(date: date(2026, 11, 10), zone: weeklyTuesdays), [.rubbish, .foodScraps],
                       "The schedule still shows the collection")

        let unpaused = NotificationService.plan(zone: weeklyTuesdays, preferences: preferences(pausedUntil: date(2026, 10, 20)), now: now)
        XCTAssertEqual(unpaused.map(\.collectionDate).min(), date(2026, 11, 3), "A pause in the past changes nothing")
        XCTAssertFalse(preferences(pausedUntil: Date(timeIntervalSince1970: .nan)).isValid)
    }

    func testPausedPreferencesCompareUnequalSoSettingsSavesAndReschedules() {
        XCTAssertNotEqual(preferences(), preferences(pausedUntil: date(2026, 11, 17)))
        XCTAssertNotEqual(preferences(), preferences(bringIn: true))
        XCTAssertEqual(preferences(), preferences())
    }

    func testNotificationCategoryOffersDoneAndRemindLaterWithoutOpeningTheApp() async {
        NotificationRouter.shared.install()
        let categories = await UNUserNotificationCenter.current().notificationCategories()
        let category = categories.first { $0.identifier == NotificationRouter.collectionCategory }
        XCTAssertEqual(category?.actions.map(\.identifier), [NotificationRouter.doneAction, NotificationRouter.snoozeAction])
        XCTAssertTrue(category?.actions.allSatisfy { !$0.options.contains(.foreground) } ?? false)
    }

    func testShareTextSpellsOutEachBinBeforeTheLinks() throws {
        LanguageManager.shared.apply("en")
        let value = zone([
            CollectionSchedule(id: "rubbish", binType: .rubbish, frequency: .weekly, anchorDate: date(2026, 11, 3)),
            CollectionSchedule(id: "recycling", binType: .recycling, frequency: .fortnightly, anchorDate: date(2026, 11, 3)),
            CollectionSchedule(id: "food", binType: .foodScraps, frequency: .weekly, anchorDate: date(2026, 11, 3))
        ])
        let lines = ScheduleLink.scheduleLines(for: value, now: date(2026, 11, 5))
        XCTAssertEqual(lines, ["Rubbish: every Tuesday", "Recycling: every second Tuesday, next 17 Nov", "Food Scraps: every Tuesday"])
        let text = try XCTUnwrap(ScheduleLink.shareText(for: value, now: date(2026, 11, 5)))
        let textLines = text.split(separator: "\n").map(String.init)
        XCTAssertEqual(textLines.count, 6)
        XCTAssertEqual(Array(textLines[1...3]), lines)
        XCTAssertTrue(textLines[4].contains("bindaynz://schedule?"))
        XCTAssertTrue(textLines[5].contains(ScheduleLink.appStoreURL.absoluteString))
    }
}
