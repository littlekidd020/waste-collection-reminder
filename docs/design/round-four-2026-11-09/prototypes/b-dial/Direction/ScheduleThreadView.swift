import SwiftUI

/// The next eight collections as beads on a vertical thread.
struct ScheduleThreadView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    static let ruleX: CGFloat = 88
    static let rowHeight: CGFloat = 96

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Eyebrow("Next eight collections")
                    Spacer()
                    Button {} label: {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Add to calendar")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)

                ZStack(alignment: .topLeading) {
                    // The thread
                    Rectangle()
                        .fill(Palette.line)
                        .frame(width: 1.5, height: Self.rowHeight * CGFloat(Sample.collections.count) - 24)
                        .offset(x: Self.ruleX - 0.75, y: 12)
                        .opacity(shown ? 1 : 0)

                    VStack(spacing: 0) {
                        ForEach(Array(Sample.collections.enumerated()), id: \.element.id) { i, c in
                            ThreadRow(index: i, collection: c,
                                      previous: i > 0 ? Sample.collections[i - 1] : nil)
                                .opacity(shown ? 1 : 0)
                                .offset(y: shown ? 0 : 12)
                                .animation(reduceMotion ? .easeOut(duration: 0.3)
                                           : .spring(response: 0.6, dampingFraction: 0.85).delay(0.04 * Double(i)), value: shown)
                        }
                    }
                }

                Label {
                    Text(Sample.holidayNotice)
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "snowflake")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                }
                .padding(.leading, Self.ruleX + 24)
                .padding(.trailing, 24)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .scrollIndicators(.hidden)
        .background(LinenGround())
        .onAppear { shown = true }
    }
}

private struct ThreadRow: View {
    let index: Int
    let collection: Sample.Collection
    let previous: Sample.Collection?

    private var monthChanged: Bool {
        guard let previous else { return true }
        return Sample.calendar.component(.month, from: previous.date) != Sample.calendar.component(.month, from: collection.date)
    }
    private var hasRecycling: Bool { collection.bins.contains(.recycling) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Day, left of the thread, right-aligned to it
            VStack(alignment: .trailing, spacing: 0) {
                Eyebrow(Sample.weekday(collection.date, short: true))
                Text(Sample.dayNumber(collection.date))
                    .font(.system(size: 34, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(width: 46, alignment: .trailing)
            .offset(x: 24, y: 14)

            // Beads on the thread
            VStack(spacing: -3) {
                ForEach(Array(collection.bins.enumerated()), id: \.element) { i, bin in
                    LidSphere(bin: bin, size: i == 0 ? 20 : 16)
                        .zIndex(Double(10 - i))
                }
            }
            .frame(width: 24)
            .offset(x: ScheduleThreadView.ruleX - 12, y: collection.bins.count == 3 ? 18 : 24)

            // Recycling week: a faint ochre tick across the thread
            if hasRecycling {
                Capsule()
                    .fill(Bin.recycling.tint.darker(0.14))
                    .frame(width: 2, height: 10)
                    .offset(x: ScheduleThreadView.ruleX - 1, y: 76)
                    .accessibilityHidden(true)
            }

            // Names, right of the thread
            VStack(alignment: .leading, spacing: 4) {
                if index == 0 || monthChanged {
                    Eyebrow([index == 0 ? "Tomorrow" : nil, monthChanged ? Sample.monthName(collection.date) : nil]
                        .compactMap { $0 }.joined(separator: " · "))
                }
                Text(Sample.list(collection.bins))
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, ScheduleThreadView.ruleX + 20)
            .padding(.trailing, 24)
            .padding(.top, index == 0 || monthChanged ? 18 : 33)
        }
        .frame(maxWidth: .infinity, minHeight: ScheduleThreadView.rowHeight, maxHeight: ScheduleThreadView.rowHeight, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Sample.weekday(collection.date)) \(Sample.dayNumber(collection.date)) \(Sample.monthName(collection.date)): \(Sample.list(collection.bins))")
    }
}
