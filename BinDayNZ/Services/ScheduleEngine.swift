import Foundation

/// Core engine that calculates waste collection dates.
/// Determines which bins are collected on any given date for a specific zone.
final class ScheduleEngine {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Public API

    /// Returns the next N upcoming collections for a zone, starting from a given date.
    func upcomingCollections(for zone: CollectionZone, from startDate: Date, count: Int) -> [UpcomingCollection] {
        var results: [UpcomingCollection] = []
        let startOfDay = calendar.startOfDay(for: startDate)

        for dayOffset in 0..<180 { // Look ahead up to 6 months
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) else { continue }
            let bins = binsCollectedOn(date: date, zone: zone)
            for bin in bins {
                results.append(UpcomingCollection(binType: bin, date: date))
            }
            if results.count >= count { break }
        }

        return Array(results.prefix(count))
    }

    /// Returns which bin types are collected on a specific date for a zone.
    func binsCollectedOn(date: Date, zone: CollectionZone) -> [BinType] {
        let weekday = calendar.component(.weekday, from: date)
        // Convert Apple's Sunday=1..Saturday=7 to ISO Monday=1..Sunday=7
        let isoDayOfWeek = weekday == 1 ? 7 : weekday - 1

        return zone.schedules.compactMap { schedule in
            guard schedule.dayOfWeek == isoDayOfWeek else { return nil }

            switch schedule.frequency {
            case .weekly:
                return schedule.binType
            case .fortnightly:
                let weekOfYear = calendar.component(.weekOfYear, from: date)
                let isEvenWeek = weekOfYear % 2 == 0
                if let pattern = schedule.weekPattern {
                    if (pattern == .even && isEvenWeek) || (pattern == .odd && !isEvenWeek) {
                        return schedule.binType
                    }
                }
                return nil
            }
        }
    }

    /// Returns the single next collection for a zone.
    func nextCollection(for zone: CollectionZone, from date: Date = Date()) -> UpcomingCollection? {
        return upcomingCollections(for: zone, from: date, count: 1).first
    }

    /// Returns all collections on a specific date, grouped for display.
    func collectionsOnDate(_ date: Date, zone: CollectionZone) -> [UpcomingCollection] {
        let bins = binsCollectedOn(date: date, zone: zone)
        return bins.map { UpcomingCollection(binType: $0, date: date) }
    }

    /// Returns collections for an entire month, keyed by day of month.
    func collectionsForMonth(year: Int, month: Int, zone: CollectionZone) -> [Int: [BinType]] {
        var result: [Int: [BinType]] = [:]

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return result
        }

        for day in range {
            components.day = day
            guard let date = calendar.date(from: components) else { continue }
            let bins = binsCollectedOn(date: date, zone: zone)
            if !bins.isEmpty {
                result[day] = bins
            }
        }

        return result
    }

    /// Returns today's collections for quick widget/notification display.
    func todaysCollections(zone: CollectionZone) -> [BinType] {
        return binsCollectedOn(date: Date(), zone: zone)
    }

    /// Returns tomorrow's collections for evening reminder.
    func tomorrowsCollections(zone: CollectionZone) -> [BinType] {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return []
        }
        return binsCollectedOn(date: tomorrow, zone: zone)
    }
}
