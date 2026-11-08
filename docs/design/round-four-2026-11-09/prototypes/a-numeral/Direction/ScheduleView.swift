import SwiftUI

struct ScheduleView: View {
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduce
    private let cal = Sample.calendar

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 8)
                    monthGrid
                        .padding(.top, 32)
                        .settle(shown, delay: 0.04, reduce: reduce)
                    upcoming
                        .padding(.top, 48)
                    holiday
                        .padding(.top, 32)
                        .settle(shown, delay: 0.3, reduce: reduce)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { shown = true }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("November 2026")
                .eyebrow(13)
                .monospacedDigit()
            Spacer()
            GlassEffectContainer {
                GlassCircleButton(symbol: "calendar.badge.clock", label: "Check dates with Auckland Council")
            }
        }
    }

    // MARK: Month grid

    private var weeks: [[Int?]] {
        // November 2026 starts on a Sunday; weeks run Monday to Sunday.
        let first = Sample.date(2026, 11, 1)
        let lead = (cal.component(.weekday, from: first) + 5) % 7 // Monday = 0
        var cells: [Int?] = Array(repeating: nil, count: lead) + (1...30).map { $0 }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    private func bins(on day: Int) -> [Bin] {
        let d = Sample.date(2026, 11, day)
        if let c = Sample.collections.first(where: { cal.isDate($0.date, inSameDayAs: d) }) { return c.bins }
        if day == 3 { return [.rubbish, .foodScraps] } // last week, the "B" fortnight
        return []
    }

    private var monthGrid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, d in
                    Text(d).eyebrow(12).frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                Rectangle().fill(Palette.line).frame(height: 0.5)
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        cell(day).frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 60)
            }
            Rectangle().fill(Palette.line).frame(height: 0.5)
        }
    }

    @ViewBuilder private func cell(_ day: Int?) -> some View {
        if let day {
            let isToday = day == 9
            let past = day < 9
            let dayBins = bins(on: day)
            VStack(spacing: 7) {
                Text("\(day)")
                    .font(.system(size: 17, weight: isToday ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isToday ? Palette.onAccent : (past ? Palette.muted.opacity(0.75) : Palette.ink))
                    .frame(width: 32, height: 32)
                    .background {
                        if isToday { Circle().fill(Palette.accent) }
                    }
                HStack(spacing: 2) {
                    ForEach(dayBins) { b in LidSphere(bin: b, size: 9) }
                }
                .frame(height: 9)
                .opacity(past ? 0.45 : 1)
            }
            .padding(.bottom, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(dayBins.isEmpty ? "\(day) November" : "\(day) November, \(Sample.list(dayBins))")
        } else {
            Color.clear
        }
    }

    // MARK: Upcoming collections

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Next collections")
                .eyebrow(13)
                .padding(.bottom, 8)
            ForEach(Array(Sample.collections.prefix(4).enumerated()), id: \.element) { i, c in
                if i > 0 { Rectangle().fill(Palette.line).frame(height: 0.5) }
                row(c, first: i == 0)
                    .settle(shown, delay: 0.12 + Double(i) * 0.04, reduce: reduce)
            }
        }
    }

    private func row(_ c: Sample.Collection, first: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(first ? "Tomorrow" : Sample.weekday(c.date, short: true))
                    .eyebrow(12)
                Text(Sample.dayNumber(c.date))
                    .font(.system(size: 34, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
            }
            .frame(width: 104, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(c.bins) { b in
                    HStack(spacing: 10) {
                        LidSphere(bin: b, size: 14)
                            .frame(height: 22)
                        Text(b.name)
                            .font(.system(size: 17))
                            .foregroundStyle(Palette.ink)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(first ? "Tomorrow" : Sample.weekday(c.date)) \(Sample.dayNumber(c.date)) \(Sample.monthName(c.date)): \(Sample.list(c.bins))")
    }

    private var holiday: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "snowflake")
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
                .accessibilityHidden(true)
            Text(Sample.holidayNotice)
                .font(.system(size: 15))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
