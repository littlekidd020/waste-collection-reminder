import SwiftUI
import UIKit

/// The next fourteen days as a street: one 56 pt kerb per day, the bins due that day standing on a
/// single horizon line inside a band of deeper linen. Scrolls sideways; each day is one element.
struct ScheduleStreet: View {
    let zone: CollectionZone
    let now: Date

    /// Height of the horizon (where the wheels touch) above the strip's bottom edge.
    static let horizon: CGFloat = 30
    static let bandHeight: CGFloat = 140
    private let engine = ScheduleEngine()
    private var calendar: Calendar { ScheduleEngine.collectionCalendar }

    private var days: [Date] {
        let start = calendar.startOfDay(for: now)
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        let today = calendar.startOfDay(for: now)
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    column(day, isToday: calendar.isDate(day, inSameDayAs: today))
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
        .background(alignment: .bottom) {
            GroundBand(returns: true, peak: 1 - Self.horizon / Self.bandHeight)
                .frame(height: Self.bandHeight)
        }
        // a fixed-width strip: the numerals stop growing before they outgrow their kerbs
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func column(_ day: Date, isToday: Bool) -> some View {
        let bins = engine.binsCollectedOn(date: day, zone: zone)
        return VStack(spacing: 0) {
            Text(verbatim: "\(calendar.component(.day, from: day))")
                .kerbFont(17, isToday ? .semibold : .regular, relativeTo: .body)
                .monospacedDigit()
                .foregroundStyle(isToday ? Palette.onAccent : Palette.ink)
                .frame(width: 32, height: 32)
                .background {
                    if isToday { Circle().fill(Palette.accent) }
                }
            Text(collectionDateLabel(day, template: "EEEEE"))
                .kerbLabel(12)
                .padding(.top, 2)

            // the kerb: bins due stand here, other days leave empty ground
            ZStack(alignment: .bottom) {
                Color.clear
                if !bins.isEmpty {
                    BinCluster(bins: bins, objectHeight: 48, preferComposite: true)
                }
            }
            .frame(height: 52)
            .padding(.top, 8)
            .padding(.bottom, Self.horizon)
        }
        .frame(width: 56)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(collectionDateLabel(day) + (isToday ? ", " + L("Today") : ""))
        .accessibilityValue(bins.isEmpty ? L("No collection") : TodayCopy.list(bins))
    }
}

/// Widths of the rendered props, so text can make room for a row of bins standing beside it.
enum SchedulePropMetrics {
    /// Width of a bin's canvas (including its transparent margins) at a full-bin height of `h`.
    static func canvasWidth(_ bin: BinType, height h: CGFloat) -> CGFloat {
        guard let image = UIImage(named: bin.propName), image.size.height > 0 else { return BinProp.fullWidth(h) }
        return h / (PropGeometry.canvasFeet - PropGeometry.canvasTop) * image.size.width / image.size.height
    }

    static func width(of bins: [BinType], height h: CGFloat, spacing: CGFloat) -> CGFloat {
        guard !bins.isEmpty else { return 0 }
        return bins.reduce(0) { $0 + canvasWidth($1, height: h) } + spacing * CGFloat(bins.count - 1)
    }
}
