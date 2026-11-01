import WidgetKit
import SwiftUI

struct BinDayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BinDayEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallWidgetView(entry: entry)
            case .systemMedium: MediumWidgetView(entry: entry)
            case .accessoryInline: LockScreenInlineView(entry: entry)
            case .accessoryCircular: LockScreenCircularView(entry: entry)
            default: SmallWidgetView(entry: entry)
            }
        }
        .environment(\.locale, Locale(identifier: entry.languageCode))
        .containerBackground(.background, for: .widget)
    }
}

private struct WidgetEmptyState: View {
    let entry: BinDayEntry

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title)
                .accessibilityHidden(true)
            Text(entry.emptyMessage)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct SmallWidgetView: View {
    let entry: BinDayEntry

    var body: some View {
        if let next = entry.nextCollection {
            WidgetDayColumn(day: next, entry: entry)
        } else {
            WidgetEmptyState(entry: entry)
        }
    }
}

struct MediumWidgetView: View {
    let entry: BinDayEntry

    var body: some View {
        if entry.collectionDays.isEmpty {
            WidgetEmptyState(entry: entry)
        } else {
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array(entry.collectionDays.prefix(2))) { day in
                    WidgetDayColumn(day: day, entry: entry)
                    if day.id != entry.collectionDays.prefix(2).last?.id { Divider() }
                }
            }
        }
    }
}

private struct WidgetDayColumn: View {
    let day: WidgetCollectionDay
    let entry: BinDayEntry

    private var relativeDate: String {
        day.relativeLabel(languageCode: entry.languageCode, relativeTo: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(relativeDate)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if relativeDate != day.dateLabel(languageCode: entry.languageCode) {
                Text(day.dateLabel(languageCode: entry.languageCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            ForEach(day.bins) { bin in
                HStack(spacing: 6) {
                    Image(systemName: bin.systemImage)
                        .symbolVariant(.none)
                        .frame(width: 16)
                    Text(widgetBinName(bin, languageCode: entry.languageCode))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.caption.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.accessibleLabel(languageCode: entry.languageCode, relativeTo: entry.date))
    }
}

struct LockScreenInlineView: View {
    let entry: BinDayEntry

    var body: some View {
        if let next = entry.nextCollection {
            let bins = next.bins.count == 1
                ? widgetBinName(next.bins[0], languageCode: entry.languageCode)
                : WL("%d bins", languageCode: entry.languageCode, next.bins.count)
            Label(next.relativeLabel(languageCode: entry.languageCode, relativeTo: entry.date) + " · " + bins, systemImage: "calendar")
                .accessibilityLabel(next.accessibleLabel(languageCode: entry.languageCode, relativeTo: entry.date))
        } else {
            Label(entry.emptyMessage, systemImage: "calendar.badge.exclamationmark")
        }
    }
}

struct LockScreenCircularView: View {
    let entry: BinDayEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let next = entry.nextCollection {
                VStack(spacing: 3) {
                    HStack(spacing: 2) {
                        ForEach(next.bins) { bin in
                            Image(systemName: bin.systemImage)
                                .symbolVariant(.none)
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    Text(next.relativeLabel(languageCode: entry.languageCode, relativeTo: entry.date))
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(next.accessibleLabel(languageCode: entry.languageCode, relativeTo: entry.date))
            } else {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title3)
                    .accessibilityLabel(entry.emptyMessage)
            }
        }
    }
}
