import SwiftUI

/// Maps the fixed moment onto a fourteen-day clock face. Angles are degrees, clockwise from twelve o'clock,
/// and twelve o'clock is "now" (Monday 9 November, 5:30 pm).
enum Fortnight {
    static let days = 14
    static let hours: Double = 336
    static var calendar: Calendar { Sample.calendar }
    static var today: Date { calendar.startOfDay(for: Sample.now) }

    /// Hours from the start of today to now (17.5).
    static var nowOffset: Double { Sample.now.timeIntervalSince(today) / 3600 }

    static func angle(for date: Date) -> Double {
        date.timeIntervalSince(Sample.now) / 3600 / hours * 360
    }
    static func dayStart(_ k: Int) -> Double { (Double(k) * 24 - nowOffset) / hours * 360 }
    static func dayCentre(_ k: Int) -> Double { (Double(k) * 24 + 12 - nowOffset) / hours * 360 }
    static func date(ofDay k: Int) -> Date { calendar.date(byAdding: .day, value: k, to: today)! }

    /// Which of the fourteen days an angle falls in.
    static func dayIndex(for angle: Double) -> Int {
        var a = angle - dayStart(0)
        a = a.truncatingRemainder(dividingBy: 360); if a < 0 { a += 360 }
        return min(days - 1, Int(a / (360 / Double(days))))
    }

    /// The next collection on or after day k.
    static func collection(onOrAfterDay k: Int) -> Sample.Collection {
        let d = date(ofDay: k)
        return Sample.collections.first { calendar.startOfDay(for: $0.date) >= d } ?? Sample.collections.last!
    }

    /// Collection time (7 am) for a collection day.
    static func putOutTime(_ c: Sample.Collection) -> Date {
        calendar.date(byAdding: .hour, value: 7, to: calendar.startOfDay(for: c.date))!
    }

    static func daysFromToday(_ date: Date) -> Int {
        calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
    }

    static func point(_ angle: Double, radius: CGFloat, centre: CGPoint) -> CGPoint {
        let r = angle * .pi / 180
        return CGPoint(x: centre.x + radius * CGFloat(sin(r)), y: centre.y - radius * CGFloat(cos(r)))
    }

    static func shortDate(_ d: Date) -> String { "\(Sample.weekday(d, short: true)) \(Sample.dayNumber(d))" }
}
