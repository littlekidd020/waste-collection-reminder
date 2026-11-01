import Foundation

/// Represents a single upcoming bin collection event.
struct UpcomingCollection: Identifiable, Equatable {
    var id: String { "\(binType.rawValue)-\(date.timeIntervalSince1970)" }
    let binType: BinType
    let date: Date

    /// Human-readable relative date label
    var relativeLabel: String {
        let calendar = ScheduleEngine.collectionCalendar
        if calendar.isDateInToday(date) {
            return L("Today")
        } else if calendar.isDateInTomorrow(date) {
            return L("Tomorrow")
        } else {
            let formatter = DateFormatter()
            formatter.locale = LanguageManager.shared.locale
            formatter.timeZone = ScheduleEngine.collectionCalendar.timeZone
            formatter.dateFormat = "EEEE d MMM"
            return formatter.string(from: date)
        }
    }

    /// True if this collection is today
    var isToday: Bool {
        ScheduleEngine.collectionCalendar.isDateInToday(date)
    }

    /// True if this collection is tomorrow
    var isTomorrow: Bool {
        ScheduleEngine.collectionCalendar.isDateInTomorrow(date)
    }

    /// Days until this collection
    var daysUntil: Int {
        let calendar = ScheduleEngine.collectionCalendar
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0
    }

    static func == (lhs: UpcomingCollection, rhs: UpcomingCollection) -> Bool {
        lhs.binType == rhs.binType && lhs.date == rhs.date
    }
}
