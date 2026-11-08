import SwiftUI

/// Numeral's boxless month: weekday initials, weeks on hairlines, the day as a numeral with its
/// collection's lid spheres in a row underneath. Today sits in the moss disc; past days recede.
struct ScheduleMonthGrid: View {
    /// The first day of the displayed month, in New Zealand.
    let month: Date
    let collections: [Int: [BinType]]
    let now: Date
    let onSelect: (Date) -> Void

    private var calendar: Calendar { ScheduleEngine.collectionCalendar }

    /// Monday-first weeks of day numbers, padded with blanks.
    private var weeks: [[Int?]] {
        let days = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let lead = (calendar.component(.weekday, from: month) + 5) % 7 // Monday = 0
        var cells: [Int?] = Array(repeating: nil, count: lead) + (1...days).map { Optional($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    /// One letter per weekday in the app's language, Monday first.
    static func weekdayInitials() -> [String] {
        var localized = ScheduleEngine.collectionCalendar
        localized.locale = LanguageManager.shared.locale
        let symbols = localized.veryShortStandaloneWeekdaySymbols
        return Array(symbols.dropFirst()) + [symbols[0]]
    }

    var body: some View {
        let today = calendar.startOfDay(for: now)
        VStack(spacing: 0) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                Hairline()
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        cell(day, today: today)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 60)
            }
            Hairline()
        }
    }

    @ViewBuilder
    private func cell(_ day: Int?, today: Date) -> some View {
        if let day, let date = calendar.date(byAdding: .day, value: day - 1, to: month) {
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let past = date < today
            let bins = collections[day, default: []]
            Button {
                onSelect(date)
            } label: {
                VStack(spacing: 7) {
                    Text(verbatim: "\(day)")
                        .kerbFont(17, isToday ? .semibold : .regular, relativeTo: .body)
                        .monospacedDigit()
                        .foregroundStyle(isToday ? Palette.onAccent : (past ? Palette.muted.opacity(0.75) : Palette.ink))
                        .frame(width: 32, height: 32)
                        .background {
                            if isToday { Circle().fill(Palette.accent) }
                        }
                    HStack(spacing: 2) {
                        ForEach(bins) { LidSphere(bin: $0, size: 9) }
                    }
                    .frame(height: 9)
                    .opacity(past ? 0.45 : 1)
                }
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(collectionDateLabel(date) + (isToday ? ", " + L("Today") : ""))
            .accessibilityValue(bins.isEmpty ? L("No collection") : TodayCopy.list(bins))
            .accessibilityHint(L("Show collection details"))
            .accessibilityAddTraits(.isButton)
        } else {
            Color.clear.accessibilityHidden(true)
        }
    }
}
