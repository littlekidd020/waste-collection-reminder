import Foundation

/// Auckland Council's published rule for the 2026–27 season, read from the regional collection
/// calendar on 1 November 2026: "If your collection is on or after a public holiday, it will be one
/// day later that week." The dated list below is the calendar's highlighted holidays. City centre
/// bag collections, Aotea / Great Barrier and private services differ, so the card always says so
/// and links the source. Review this list every release.
struct PublicHoliday: Identifiable, Hashable {
    let id: String
    let localizedName: () -> String
    let year: Int
    let month: Int
    let day: Int

    var name: String { localizedName() }
    static func == (lhs: PublicHoliday, rhs: PublicHoliday) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var date: Date {
        ScheduleEngine.collectionCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static let sourceURL = URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/public-holiday-collections.html")!
    static let reviewedOn = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 1).date!

    /// Mondayised Boxing Day (28 Dec 2026) is not marked in the council calendar and is left out until confirmed.
    static let season2026_27: [PublicHoliday] = [
        PublicHoliday(id: "christmas-2026", localizedName: { L("Christmas Day") }, year: 2026, month: 12, day: 25),
        PublicHoliday(id: "new-year-2027", localizedName: { L("New Year's Day") }, year: 2027, month: 1, day: 1),
        PublicHoliday(id: "day-after-new-year-2027", localizedName: { L("Day after New Year's Day") }, year: 2027, month: 1, day: 4),
        PublicHoliday(id: "auckland-anniversary-2027", localizedName: { L("Auckland Anniversary Day") }, year: 2027, month: 2, day: 1),
        PublicHoliday(id: "waitangi-2027", localizedName: { L("Waitangi Day") }, year: 2027, month: 2, day: 8),
        PublicHoliday(id: "good-friday-2027", localizedName: { L("Good Friday") }, year: 2027, month: 3, day: 26),
        PublicHoliday(id: "easter-monday-2027", localizedName: { L("Easter Monday") }, year: 2027, month: 3, day: 29),
        PublicHoliday(id: "anzac-2027", localizedName: { L("Anzac Day") }, year: 2027, month: 4, day: 26),
        PublicHoliday(id: "kings-birthday-2027", localizedName: { L("King's Birthday") }, year: 2027, month: 6, day: 7),
        PublicHoliday(id: "matariki-2027", localizedName: { L("Matariki") }, year: 2027, month: 6, day: 25)
    ]
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
    var id: String { holiday.id }
}

enum HolidayShiftService {
    static let leadDays = 21

    /// Suggestions for the saved schedule within the lead window, skipping dates the user already changed.
    static func suggestions(for zone: CollectionZone, holidays: [PublicHoliday] = PublicHoliday.season2026_27,
                            now: Date = Date(), dismissed: Set<String> = []) -> [HolidaySuggestion] {
        let calendar = ScheduleEngine.collectionCalendar
        let today = calendar.startOfDay(for: now)
        return holidays.compactMap { holiday in
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
            return moves.isEmpty ? nil : HolidaySuggestion(holiday: holiday, moves: moves)
        }
    }

    /// The zone with the suggestion's moves recorded as one-off changes, or nil if the result would be invalid.
    static func applying(_ suggestion: HolidaySuggestion, to zone: CollectionZone) -> CollectionZone? {
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
