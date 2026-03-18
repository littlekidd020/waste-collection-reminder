import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

/// Data entry for the Bin Day widget timeline.
struct BinDayEntry: TimelineEntry {
    let date: Date
    let collections: [WidgetCollection]
    let nextCollection: WidgetCollection?
}

/// A simplified collection for widget display.
struct WidgetCollection {
    let binType: String // raw value
    let binIcon: String
    let binName: String
    let collectionDate: Date
    let relativeLabel: String
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
}

// MARK: - Timeline Provider

struct BinDayTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> BinDayEntry {
        BinDayEntry(
            date: Date(),
            collections: [
                WidgetCollection(
                    binType: "rubbish", binIcon: "🔴", binName: "Rubbish",
                    collectionDate: Date(), relativeLabel: "Tomorrow",
                    colorRed: 0.85, colorGreen: 0.2, colorBlue: 0.2
                )
            ],
            nextCollection: WidgetCollection(
                binType: "rubbish", binIcon: "🔴", binName: "Rubbish",
                collectionDate: Date(), relativeLabel: "Tomorrow",
                colorRed: 0.85, colorGreen: 0.2, colorBlue: 0.2
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BinDayEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BinDayEntry>) -> Void) {
        // Load collections from shared App Group UserDefaults
        let collections = loadCollectionsFromAppGroup()
        let entry = BinDayEntry(
            date: Date(),
            collections: collections,
            nextCollection: collections.first
        )

        // Refresh at midnight or when the next collection changes
        let nextRefresh = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    /// Load collections from the shared App Group storage.
    /// The main app writes this data for the widget to read.
    private func loadCollectionsFromAppGroup() -> [WidgetCollection] {
        // TODO: Read from App Group UserDefaults
        // For now, return sample data
        return [
            WidgetCollection(
                binType: "rubbish", binIcon: "🔴", binName: "Rubbish",
                collectionDate: Date(), relativeLabel: "Tomorrow",
                colorRed: 0.85, colorGreen: 0.2, colorBlue: 0.2
            ),
            WidgetCollection(
                binType: "recycling", binIcon: "🟡", binName: "Recycling",
                collectionDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                relativeLabel: "Thursday",
                colorRed: 0.95, colorGreen: 0.8, colorBlue: 0.1
            ),
            WidgetCollection(
                binType: "foodScraps", binIcon: "🟢", binName: "Food Scraps",
                collectionDate: Date(), relativeLabel: "Tomorrow",
                colorRed: 0.2, colorGreen: 0.75, colorBlue: 0.3
            )
        ]
    }
}

// MARK: - Widget Bundle

@main
struct BinDayNZWidgetBundle: WidgetBundle {
    var body: some Widget {
        BinDayNZWidget()
    }
}

struct BinDayNZWidget: Widget {
    let kind = "BinDayNZWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BinDayTimelineProvider()) { entry in
            BinDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bin Day NZ")
        .description("See your upcoming bin collection at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular])
    }
}
