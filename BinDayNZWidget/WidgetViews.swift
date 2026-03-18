import WidgetKit
import SwiftUI

/// Unified widget entry view that adapts to different widget families.
struct BinDayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BinDayEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2×2)

/// Shows the next bin type with colour background and date.
struct SmallWidgetView: View {
    let entry: BinDayEntry

    var body: some View {
        if let next = entry.nextCollection {
            VStack(alignment: .leading, spacing: 8) {
                // Bin icon
                Text(next.binIcon)
                    .font(.system(size: 36))

                Spacer()

                // Bin name
                Text(next.binName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Date
                Text(next.relativeLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: next.colorRed, green: next.colorGreen, blue: next.colorBlue),
                        Color(red: next.colorRed * 0.7, green: next.colorGreen * 0.7, blue: next.colorBlue * 0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("All clear!")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

// MARK: - Medium Widget (4×2)

/// Shows the next 3 upcoming collections in a row.
struct MediumWidgetView: View {
    let entry: BinDayEntry

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(entry.collections.prefix(3).enumerated()), id: \.offset) { _, collection in
                VStack(spacing: 8) {
                    Text(collection.binIcon)
                        .font(.system(size: 28))

                    Text(collection.binName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(collection.relativeLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: collection.colorRed, green: collection.colorGreen, blue: collection.colorBlue).opacity(0.8),
                                    Color(red: collection.colorRed, green: collection.colorGreen, blue: collection.colorBlue).opacity(0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.08))
    }
}

// MARK: - Lock Screen Widgets

/// Lock screen inline widget — shows a single line of text.
struct LockScreenInlineView: View {
    let entry: BinDayEntry

    var body: some View {
        if let next = entry.nextCollection {
            Text("\(next.binIcon) \(next.binName) \(next.relativeLabel.lowercased())")
        } else {
            Text("✅ No collection today")
        }
    }
}

/// Lock screen circular widget — shows the bin icon.
struct LockScreenCircularView: View {
    let entry: BinDayEntry

    var body: some View {
        if let next = entry.nextCollection {
            ZStack {
                AccessoryWidgetBackground()
                Text(next.binIcon)
                    .font(.title2)
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "checkmark")
                    .font(.title3)
            }
        }
    }
}
