import SwiftUI

/// Three gauges, one per bin, whose arcs show how often each is collected.
struct GuideGaugesView: View {
    @State private var selected: Bin = .recycling
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private func nextDate(_ bin: Bin) -> Date {
        Sample.collections.first { $0.bins.contains(bin) }!.date
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Eyebrow(Sample.council)
                    Spacer()
                    Button {} label: {
                        Image(systemName: "safari")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Open the council page")
                }
                .padding(.top, 8)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(Sample.guideBins.enumerated()), id: \.element) { i, bin in
                        Gauge(bin: bin, selected: bin == selected, shown: shown, order: i)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { selected = bin }
                            }
                            .accessibilityAddTraits(bin == selected ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.top, 32)
                .sensoryFeedback(.selection, trigger: selected)

                detail
                    .id(selected)
                    .transition(.opacity)
                    .padding(.top, 40)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background(LinenGround())
        .onAppear { shown = true }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(selected.name)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.5)
            Text("\(selected.frequency) · next \(Fortnight.shortDate(nextDate(selected))) \(Sample.monthName(nextDate(selected), short: true))")
                .font(.system(size: 15))
                .monospacedDigit()
                .foregroundStyle(Palette.muted)
                .padding(.top, 4)
            Text(Sample.blurb(selected))
                .font(.system(size: 17))
                .foregroundStyle(Palette.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            HStack(alignment: .top, spacing: 0) {
                column("Yes", Sample.accepted(selected), color: Palette.ink)
                Rectangle().fill(Palette.line).frame(width: 1).padding(.horizontal, 16)
                column("No", Sample.refused(selected), color: Palette.muted)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 32)
        }
    }

    private func column(_ title: String, _ items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(title)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Gauge: View {
    let bin: Bin
    let selected: Bool
    let shown: Bool
    let order: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var share: CGFloat { bin.frequency == "Weekly" ? 1 : 0.5 }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                TorusRing(outer: 96, tube: 10, draw: shown ? 1 : 0,
                          fill: (bin.lid.opacity(0.70), share, share < 1),
                          shadowRadius: selected ? 14 : 8, shadowY: selected ? 8 : 4,
                          shadowOpacity: selected ? 0.22 : 0.10)
                LidSphere(bin: bin, size: 28, raised: selected)
            }
            .frame(width: 96, height: 96)
            .scaleEffect(selected ? 1.08 : 1)
            .opacity(selected ? 1 : 0.7)
            .animation(reduceMotion ? .easeOut(duration: 0.3)
                       : .timingCurve(0.45, 0, 0.2, 1, duration: 0.7).delay(0.06 * Double(order)), value: shown)

            Eyebrow(bin.name, color: selected ? Palette.ink : Palette.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bin.name), \(bin.frequency.lowercased())")
    }
}
