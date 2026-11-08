import SwiftUI

/// One day from the calendar: the date set as a numeral, the bins due standing on a strip of
/// deeper linen, then their names. Presented as a sheet from Schedule.
struct DayDetailView: View {
    let date: Date
    let zone: CollectionZone?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var width: CGFloat = 360

    private var calendar: Calendar { ScheduleEngine.collectionCalendar }
    private var bins: [BinType] { zone.map { ScheduleEngine().binsCollectedOn(date: date, zone: $0) } ?? [] }

    var body: some View {
        ZStack {
            LinenGround()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Text(L("Collection details"))
                            .kerbLabel()
                        Spacer(minLength: 16)
                        Button {
                            dismiss()
                        } label: {
                            Text(L("Done"))
                                .kerbFont(17, .semibold, relativeTo: .body)
                                .foregroundStyle(Palette.ink)
                                .padding(.horizontal, 4)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                    }
                    .padding(.top, 20)

                    dateBlock
                        .padding(.top, 16)

                    if bins.isEmpty {
                        Text(L("No collection on this day"))
                            .kerbFont(17, relativeTo: .body)
                            .foregroundStyle(Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 24)
                    } else {
                        props
                            .padding(.top, 28)
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(bins) { bin in
                                CollectionBinRow(bin: bin, sphere: 16)
                                    .kerbFont(17, relativeTo: .body)
                            }
                        }
                        .padding(.top, 52)
                        .opacity(shown ? 1 : 0)
                        .offset(y: shown || reduceMotion ? 0 : 10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .frame(maxWidth: 600, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.3) : .spring(response: 0.6, dampingFraction: 0.85).delay(0.1)) {
                shown = true
            }
        }
    }

    private var dateBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(collectionDateLabel(date, template: "EEEE"))
                .kerbLabel(12)
            Text(verbatim: "\(calendar.component(.day, from: date))")
                .kerbFont(34, .light, relativeTo: .largeTitle)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            Text(collectionDateLabel(date, template: "MMMM yyyy"))
                .kerbFont(15, relativeTo: .subheadline)
                .foregroundStyle(Palette.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(collectionDateLabel(date, template: "EEEE d MMMM yyyy"))
        .accessibilityAddTraits(.isHeader)
    }

    /// The bins at up to 120 pt, scaled down so a five-bin household still fits the width.
    private var props: some View {
        let gap: CGFloat = -16
        let unit = SchedulePropMetrics.width(of: bins, height: 1, spacing: 0)
        let fit = (width - 48 - gap * CGFloat(bins.count - 1)) / max(unit, 0.01)
        let height = min(120, fit)
        let band: CGFloat = 150
        let peak: CGFloat = 0.72
        return HStack(alignment: .bottom, spacing: gap) {
            ForEach(Array(bins.enumerated()), id: \.element) { i, bin in
                BinProp(bin: bin, objectHeight: height)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown || reduceMotion ? 0 : 12)
                    .animation(reduceMotion ? .easeOut(duration: 0.3) : .spring(response: 0.6, dampingFraction: 0.85).delay(0.04 * Double(i)), value: shown)
            }
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            GroundBand(returns: true, peak: peak)
                .frame(height: band)
                .offset(y: band * (1 - peak))
                .padding(.horizontal, -24)
        }
        // the rows below name each bin, so the picture stays quiet for VoiceOver
        .accessibilityHidden(true)
    }
}
