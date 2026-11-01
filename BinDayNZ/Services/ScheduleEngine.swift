import Foundation

final class ScheduleEngine {
    /// Built once. `Calendar` is a value type, so sharing it across call sites and threads is safe.
    static let collectionCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Pacific/Auckland")!
        calendar.firstWeekday = 2
        return calendar
    }()

    func binsCollectedOn(date: Date, zone: CollectionZone) -> [BinType] {
        guard date.timeIntervalSince1970.isFinite, zone.isValid else { return [] }
        let calendar = Self.collectionCalendar
        return zone.schedules.filter(\.isValid).compactMap { schedule in
            if schedule.changes.contains(where: { $0.replacementDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false }) {
                return schedule.binType
            }
            if schedule.changes.contains(where: { calendar.isDate($0.originalDate, inSameDayAs: date) }) { return nil }
            return schedule.isRegularCollection(on: date) ? schedule.binType : nil
        }.sorted { BinType.allCases.firstIndex(of: $0)! < BinType.allCases.firstIndex(of: $1)! }
    }

    func upcomingCollections(for zone: CollectionZone, from startDate: Date, count: Int) -> [UpcomingCollection] {
        guard count > 0, startDate.timeIntervalSince1970.isFinite, zone.isValid else { return [] }
        let calendar = Self.collectionCalendar
        let start = calendar.startOfDay(for: startDate)
        var dates = Set<Date>()
        for schedule in zone.schedules {
            let anchor = calendar.startOfDay(for: schedule.anchorDate)
            let elapsed = max(0, calendar.dateComponents([.day], from: anchor, to: start).day ?? 0)
            let offset = ((elapsed + schedule.frequency.intervalDays - 1) / schedule.frequency.intervalDays) * schedule.frequency.intervalDays
            // Each removed occurrence needs one extra candidate; replacements are added below.
            for index in 0..<(count + schedule.changes.count) {
                if let date = calendar.date(byAdding: .day, value: offset + index * schedule.frequency.intervalDays, to: anchor), date >= start {
                    dates.insert(date)
                }
            }
            for change in schedule.changes {
                if let date = change.replacementDate.map({ calendar.startOfDay(for: $0) }), date >= start { dates.insert(date) }
            }
        }
        return dates.sorted().flatMap { date in
            binsCollectedOn(date: date, zone: zone).map { UpcomingCollection(binType: $0, date: date) }
        }.prefix(count).map { $0 }
    }

    func nextCollection(for zone: CollectionZone, from date: Date = Date()) -> UpcomingCollection? {
        upcomingCollections(for: zone, from: date, count: 1).first
    }

    func collectionsForMonth(year: Int, month: Int, zone: CollectionZone) -> [Int: [BinType]] {
        let calendar = Self.collectionCalendar
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let days = calendar.range(of: .day, in: .month, for: first) else { return [:] }
        return Dictionary(uniqueKeysWithValues: days.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: first) else { return nil }
            let bins = binsCollectedOn(date: date, zone: zone)
            return bins.isEmpty ? nil : (day, bins)
        })
    }
}
