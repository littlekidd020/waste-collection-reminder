import SwiftUI

/// Schedule: a street of fourteen kerbs, then the next six collections set as type with their bins on a hairline.
struct ScheduleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// Height of the strip's horizon (the band's deepest line, where the wheels touch) above its bottom edge.
    static let horizon: CGFloat = 30
    private let cal = Sample.calendar
    private var days: [Date] {
        let start = cal.startOfDay(for: Sample.now)
        return (0..<14).map { cal.date(byAdding: .day, value: $0, to: start)! }
    }
    private func bins(on day: Date) -> [Bin]? {
        Sample.collections.first { cal.isDate($0.date, inSameDayAs: day) }?.bins
    }

    var body: some View {
        ZStack {
            LinenGround()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    street
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        ForEach(Array(Sample.collections.prefix(6).enumerated()), id: \.element.id) { i, c in
                            row(c, index: i)
                                .opacity(shown ? 1 : 0)
                                .offset(y: shown || reduceMotion ? 0 : 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.04 * Double(i) + 0.1), value: shown)
                        }
                    }
                    .padding(.horizontal, 24)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 15))
                        Text(Sample.holidayNotice)
                            .font(.system(size: 15))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { shown = true }
    }

    private var header: some View {
        HStack {
            Text("The next fortnight").kerbLabel()
            Spacer()
            GlassEffectContainer {
                GlassCircleButton(systemImage: "calendar.badge.clock", label: "Add to calendar")
            }
        }
    }

    // MARK: The street strip

    private var street: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    column(day, isToday: i == 0)
                }
            }
            .padding(.horizontal, 12)
            .background(alignment: .bottom) {
                // the kerb edge: one faint line the whole street stands on
                Rectangle()
                    .fill(Palette.line.opacity(0.7))
                    .frame(height: 1)
                    .padding(.bottom, Self.horizon - 0.5)
            }
        }
        .scrollIndicators(.hidden)
        .background(GroundBand(returns: true, peak: 1 - Self.horizon / 140).frame(height: 140), alignment: .bottom)
    }

    private func column(_ day: Date, isToday: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if isToday {
                    Circle().fill(Palette.accent).frame(width: 32, height: 32)
                }
                Text(Sample.dayNumber(day))
                    .font(.system(size: 17, weight: isToday ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isToday ? Palette.onAccent : Palette.ink)
            }
            .frame(height: 32)
            Text(String(Sample.weekday(day, short: true).prefix(1)))
                .kerbLabel(12)
                .padding(.top, 2)

            // the kerb: bins due stand here, others leave empty ground
            ZStack(alignment: .bottom) {
                Color.clear
                if let b = bins(on: day) {
                    BinCluster(bins: b, objectHeight: 48)
                }
            }
            .frame(height: 52)
            .padding(.top, 8)
            .padding(.bottom, Self.horizon)
        }
        .frame(width: 56)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(columnLabel(day, isToday: isToday))
    }

    private func columnLabel(_ day: Date, isToday: Bool) -> String {
        let when = "\(Sample.weekday(day)) \(Sample.dayNumber(day)) \(Sample.monthName(day))"
        if let b = bins(on: day) { return "\(when): \(Sample.list(b))" }
        return isToday ? "Today, \(when): no collection" : "\(when): no collection"
    }

    // MARK: Next collections

    private func row(_ c: Sample.Collection, index i: Int) -> some View {
        let prev = i > 0 ? Sample.collections[i - 1].date : Sample.now
        let newMonth = cal.component(.month, from: c.date) != cal.component(.month, from: prev)
        // the first row of a new month names the month instead of the (always Tuesday) weekday
        let label: String = i == 0 ? "Tomorrow" : (newMonth ? Sample.monthName(c.date) : Sample.weekday(c.date))
        let recyclingWeek = c.bins.contains(.recycling)

        return ZStack(alignment: .bottom) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(label).kerbLabel(12)
                    Text(Sample.dayNumber(c.date))
                        .font(.system(size: 34, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(Palette.ink)
                }
                .frame(width: 96, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Sample.list(c.bins))
                        .font(.system(size: 17))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(recyclingWeek ? "Recycling week" : "No recycling")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.trailing, 64)
            .padding(.bottom, 8)
            .frame(maxHeight: .infinity, alignment: .center)

            HStack(alignment: .bottom, spacing: 0) {
                Spacer()
                HStack(alignment: .bottom, spacing: -5) {
                    ForEach(c.bins) { BinProp(bin: $0, objectHeight: 32) }
                }
            }

            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
                .offset(y: 0.5)
        }
        .frame(height: 92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(i == 0 ? "Tomorrow, " : "")\(Sample.weekday(c.date)) \(Sample.dayNumber(c.date)) \(Sample.monthName(c.date)): \(Sample.list(c.bins))")
    }
}
