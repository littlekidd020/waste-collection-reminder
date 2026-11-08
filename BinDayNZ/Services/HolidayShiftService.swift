import Foundation

/// New Zealand public holidays for the 2026–27 season, with each region's anniversary day.
/// Dates were checked on 7 November 2026 against the Employment New Zealand holiday list; the
/// national dates match the highlighted holidays on Auckland Council's regional collection
/// calendar read on 1 November 2026. Review this list every release.
struct PublicHoliday: Identifiable, Hashable {
    let id: String
    let localizedName: () -> String
    let year: Int
    let month: Int
    let day: Int
    /// Nil for a national holiday; otherwise only councils observing that anniversary see it.
    let anniversary: AnniversaryDay?

    init(id: String, localizedName: @escaping () -> String, year: Int, month: Int, day: Int, anniversary: AnniversaryDay? = nil) {
        self.id = id
        self.localizedName = localizedName
        self.year = year
        self.month = month
        self.day = day
        self.anniversary = anniversary
    }

    var name: String { localizedName() }
    static func == (lhs: PublicHoliday, rhs: PublicHoliday) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var date: Date {
        ScheduleEngine.collectionCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func applies(to council: Council) -> Bool {
        anniversary == nil || anniversary == council.anniversary
    }

    static let reviewedOn = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 7).date!

    /// Mondayised Boxing Day (28 Dec 2026) is not marked in the Auckland calendar and is left out until confirmed.
    static let season2026_27: [PublicHoliday] = [
        PublicHoliday(id: "christmas-2026", localizedName: { L("Christmas Day") }, year: 2026, month: 12, day: 25),
        PublicHoliday(id: "new-year-2027", localizedName: { L("New Year's Day") }, year: 2027, month: 1, day: 1),
        PublicHoliday(id: "day-after-new-year-2027", localizedName: { L("Day after New Year's Day") }, year: 2027, month: 1, day: 4),
        PublicHoliday(id: "wellington-anniversary-2027", localizedName: { L("Wellington Anniversary Day") }, year: 2027, month: 1, day: 25, anniversary: .wellington),
        PublicHoliday(id: "auckland-anniversary-2027", localizedName: { L("Auckland Anniversary Day") }, year: 2027, month: 2, day: 1, anniversary: .auckland),
        PublicHoliday(id: "nelson-anniversary-2027", localizedName: { L("Nelson Anniversary Day") }, year: 2027, month: 2, day: 1, anniversary: .nelson),
        PublicHoliday(id: "waitangi-2027", localizedName: { L("Waitangi Day") }, year: 2027, month: 2, day: 8),
        PublicHoliday(id: "taranaki-anniversary-2027", localizedName: { L("Taranaki Anniversary Day") }, year: 2027, month: 3, day: 8, anniversary: .taranaki),
        PublicHoliday(id: "otago-anniversary-2027", localizedName: { L("Otago Anniversary Day") }, year: 2027, month: 3, day: 22, anniversary: .otago),
        PublicHoliday(id: "good-friday-2027", localizedName: { L("Good Friday") }, year: 2027, month: 3, day: 26),
        PublicHoliday(id: "easter-monday-2027", localizedName: { L("Easter Monday") }, year: 2027, month: 3, day: 29),
        PublicHoliday(id: "southland-anniversary-2027", localizedName: { L("Southland Anniversary Day") }, year: 2027, month: 3, day: 30, anniversary: .southland),
        PublicHoliday(id: "anzac-2027", localizedName: { L("Anzac Day") }, year: 2027, month: 4, day: 26),
        PublicHoliday(id: "kings-birthday-2027", localizedName: { L("King's Birthday") }, year: 2027, month: 6, day: 7),
        PublicHoliday(id: "matariki-2027", localizedName: { L("Matariki") }, year: 2027, month: 6, day: 25),
        PublicHoliday(id: "south-canterbury-anniversary-2027", localizedName: { L("South Canterbury Anniversary Day") }, year: 2027, month: 9, day: 27, anniversary: .southCanterbury),
        PublicHoliday(id: "hawkes-bay-anniversary-2027", localizedName: { L("Hawke's Bay Anniversary Day") }, year: 2027, month: 10, day: 22, anniversary: .hawkesBay),
        PublicHoliday(id: "labour-day-2027", localizedName: { L("Labour Day") }, year: 2027, month: 10, day: 25),
        PublicHoliday(id: "marlborough-anniversary-2027", localizedName: { L("Marlborough Anniversary Day") }, year: 2027, month: 11, day: 1, anniversary: .marlborough),
        PublicHoliday(id: "canterbury-anniversary-2027", localizedName: { L("Canterbury Anniversary Day") }, year: 2027, month: 11, day: 12, anniversary: .canterbury),
        PublicHoliday(id: "chatham-islands-anniversary-2027", localizedName: { L("Chatham Islands Anniversary Day") }, year: 2027, month: 11, day: 29, anniversary: .chathamIslands),
        PublicHoliday(id: "westland-anniversary-2027", localizedName: { L("Westland Anniversary Day") }, year: 2027, month: 11, day: 29, anniversary: .westland)
    ]

    /// The season's holidays that a council observes.
    static func holidays(for council: Council) -> [PublicHoliday] {
        season2026_27.filter { $0.applies(to: council) }
    }
}

/// One proposed move for one bin.
struct HolidayMove: Hashable, Identifiable {
    let binType: BinType
    let original: Date
    let replacement: Date
    var id: String { "\(binType.rawValue)-\(original.timeIntervalSince1970)" }
}

struct HolidaySuggestion: Identifiable {
    let holiday: PublicHoliday
    let moves: [HolidayMove]
    /// Whether the moves follow a verified council rule and may be applied with one tap.
    let policy: HolidayPolicy
    var id: String { holiday.id }
}

enum HolidayShiftService {
    static let leadDays = 21

    /// Suggestions for the saved schedule within the lead window, skipping dates the user already changed.
    /// Only the council's own holidays are considered; moves are proposals unless the policy is verified.
    static func suggestions(for zone: CollectionZone, council: Council, holidays: [PublicHoliday]? = nil,
                            now: Date = Date(), dismissed: Set<String> = []) -> [HolidaySuggestion] {
        let calendar = ScheduleEngine.collectionCalendar
        let today = calendar.startOfDay(for: now)
        return (holidays ?? PublicHoliday.holidays(for: council)).compactMap { holiday in
            guard !dismissed.contains(holiday.id) else { return nil }
            let holidayDate = holiday.date
            let weekStart = startOfWeek(containing: holidayDate)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let visibleFrom = calendar.date(byAdding: .day, value: -leadDays, to: holidayDate)!
            guard today >= visibleFrom, today <= weekEnd else { return nil }
            var moves: [HolidayMove] = []
            for schedule in zone.schedules {
                var date = holidayDate
                while date <= weekEnd {
                    let alreadyChanged = schedule.changes.contains { calendar.isDate($0.originalDate, inSameDayAs: date) }
                    if date >= today, !alreadyChanged, schedule.isRegularCollection(on: date) {
                        moves.append(HolidayMove(binType: schedule.binType, original: date,
                                                 replacement: calendar.date(byAdding: .day, value: 1, to: date)!))
                    }
                    date = calendar.date(byAdding: .day, value: 1, to: date)!
                }
            }
            return moves.isEmpty ? nil : HolidaySuggestion(holiday: holiday, moves: moves, policy: council.holidayPolicy)
        }
    }

    /// The zone with the suggestion's moves recorded as one-off changes, or nil if the result would be invalid
    /// or the council's rule is not verified.
    static func applying(_ suggestion: HolidaySuggestion, to zone: CollectionZone) -> CollectionZone? {
        guard suggestion.policy.appliesAutomatically else { return nil }
        let schedules = zone.schedules.map { schedule -> CollectionSchedule in
            var updated = schedule
            for move in suggestion.moves where move.binType == schedule.binType {
                updated.changes.removeAll { ScheduleEngine.collectionCalendar.isDate($0.originalDate, inSameDayAs: move.original) }
                updated.changes.append(CollectionDateChange(originalDate: move.original, replacementDate: move.replacement))
            }
            return updated
        }
        let updated = CollectionZone(id: zone.id, name: zone.name, suburbs: zone.suburbs, schedules: schedules)
        return updated.isValid ? updated : nil
    }

    static func startOfWeek(containing date: Date) -> Date {
        let calendar = ScheduleEngine.collectionCalendar
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day) // Sunday = 1
        let offset = (weekday + 5) % 7 // Monday = 0
        return calendar.date(byAdding: .day, value: -offset, to: day)!
    }
}
