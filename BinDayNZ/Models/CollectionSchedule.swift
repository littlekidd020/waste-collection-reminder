import Foundation

enum Frequency: String, Codable, CaseIterable {
    case weekly, fortnightly
    var intervalDays: Int { self == .weekly ? 7 : 14 }
}

/// A single changed occurrence. A nil replacement cancels that collection.
struct CollectionDateChange: Codable, Hashable, Identifiable {
    var originalDate: Date
    var replacementDate: Date?
    var id: Date { originalDate }
}

/// Recurrence is anchored to a confirmed date, never a locale's week number.
struct CollectionSchedule: Codable, Identifiable, Hashable {
    let id: String
    let binType: BinType
    var frequency: Frequency
    var anchorDate: Date
    var changes: [CollectionDateChange] = []

    var dayOfWeek: Int {
        let day = ScheduleEngine.collectionCalendar.component(.weekday, from: anchorDate)
        return day == 1 ? 7 : day - 1
    }

    func isRegularCollection(on date: Date) -> Bool {
        guard anchorDate.timeIntervalSince1970.isFinite, date.timeIntervalSince1970.isFinite else { return false }
        let calendar = ScheduleEngine.collectionCalendar
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: anchorDate), to: calendar.startOfDay(for: date)).day ?? -1
        return days >= 0 && days.isMultiple(of: frequency.intervalDays)
    }

    var isValid: Bool {
        let calendar = ScheduleEngine.collectionCalendar
        guard binType != .inorganic, anchorDate.timeIntervalSince1970.isFinite,
              !id.isEmpty, changes.allSatisfy({ $0.originalDate.timeIntervalSince1970.isFinite && ($0.replacementDate?.timeIntervalSince1970.isFinite ?? true) }), Set(changes.map { calendar.startOfDay(for: $0.originalDate) }).count == changes.count else { return false }
        let replacements = changes.compactMap { $0.replacementDate.map { calendar.startOfDay(for: $0) } }
        guard Set(replacements).count == replacements.count else { return false }
        return changes.allSatisfy { change in
            guard change.originalDate.timeIntervalSince1970.isFinite, isRegularCollection(on: change.originalDate) else { return false }
            guard let replacement = change.replacementDate else { return true }
            guard replacement.timeIntervalSince1970.isFinite, replacement >= calendar.startOfDay(for: anchorDate) else { return false }
            return !isRegularCollection(on: replacement)
                || changes.contains { calendar.isDate($0.originalDate, inSameDayAs: replacement) }
        }
    }
}
