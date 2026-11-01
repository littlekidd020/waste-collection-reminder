import WidgetKit
import SwiftUI

struct BinDayEntry: TimelineEntry {
    let date: Date
    let collectionDays: [WidgetCollectionDay]
    let languageCode: String
    let isConfigured: Bool

    var nextCollection: WidgetCollectionDay? { collectionDays.first }
    var emptyMessage: String {
        isConfigured ? WL("Check your schedule in Bin Day NZ", languageCode: languageCode) : WL("Confirm your schedule in Bin Day NZ", languageCode: languageCode)
    }
}

struct WidgetCollectionDay: Identifiable {
    let date: Date
    let bins: [BinType]
    var id: Date { date }

    func relativeLabel(languageCode: String, relativeTo now: Date) -> String {
        let calendar = ScheduleEngine.collectionCalendar
        if calendar.isDate(date, inSameDayAs: now) { return WL("Today", languageCode: languageCode) }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return WL("Tomorrow", languageCode: languageCode)
        }
        return dateLabel(languageCode: languageCode)
    }

    func dateLabel(languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = ScheduleEngine.collectionCalendar
        formatter.timeZone = ScheduleEngine.collectionCalendar.timeZone
        formatter.locale = Locale(identifier: languageCode)
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter.string(from: date)
    }

    func accessibleLabel(languageCode: String, relativeTo now: Date) -> String {
        relativeLabel(languageCode: languageCode, relativeTo: now) + ": "
            + bins.map { widgetBinName($0, languageCode: languageCode) }.joined(separator: ", ")
    }
}

struct BinDayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BinDayEntry {
        BinDayEntry(
            date: Date(),
            collectionDays: [WidgetCollectionDay(date: Date(), bins: [.rubbish, .recycling])],
            languageCode: "en",
            isConfigured: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BinDayEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : Self.entry(snapshot: loadSnapshot(), at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BinDayEntry>) -> Void) {
        let now = Date()
        let calendar = ScheduleEngine.collectionCalendar
        let startOfToday = calendar.startOfDay(for: now)
        let snapshot = loadSnapshot()
        let dates = [now] + (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfToday) }
        let entries = dates.map { Self.entry(snapshot: snapshot, at: $0) }
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        completion(Timeline(entries: entries, policy: .after(nextDay)))
    }

    private func loadSnapshot() -> WidgetScheduleSnapshot? {
        UserDefaults(suiteName: WidgetScheduleSnapshot.appGroupID).flatMap { WidgetScheduleSnapshot.load(from: $0) }
    }

    static func entry(snapshot: WidgetScheduleSnapshot?, at date: Date) -> BinDayEntry {
        guard let snapshot, snapshot.confirmedAt != nil, snapshot.zone.isValid else {
            return BinDayEntry(date: date, collectionDays: [], languageCode: snapshot?.languageCode ?? "en", isConfigured: false)
        }
        let engine = ScheduleEngine()
        let upcoming = engine.upcomingCollections(for: snapshot.zone, from: date, count: 12)
        let days = Set(upcoming.map(\.date)).sorted().prefix(3).map { collectionDate in
            WidgetCollectionDay(date: collectionDate, bins: engine.binsCollectedOn(date: collectionDate, zone: snapshot.zone))
        }
        return BinDayEntry(date: date, collectionDays: days, languageCode: snapshot.languageCode, isConfigured: true)
    }
}

/// Entry-scoped lookup avoids one widget's preview changing another entry's language.
func WL(_ key: String, languageCode: String, _ args: CVarArg...) -> String {
    let bundle = Bundle.main.path(forResource: languageCode, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    let format = bundle.localizedString(forKey: key, value: key, table: nil)
    return args.isEmpty ? format : String(format: format, locale: Locale(identifier: languageCode), arguments: args)
}

func widgetBinName(_ bin: BinType, languageCode: String) -> String {
    switch bin {
    case .rubbish: return WL("Rubbish", languageCode: languageCode)
    case .recycling: return WL("Recycling", languageCode: languageCode)
    case .foodScraps: return WL("Food Scraps", languageCode: languageCode)
    case .inorganic: return WL("Inorganic Collection", languageCode: languageCode)
    }
}

@main
struct BinDayNZWidgetBundle: WidgetBundle {
    var body: some Widget { BinDayNZWidget() }
}

struct BinDayNZWidget: Widget {
    let kind = "BinDayNZWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BinDayTimelineProvider()) { entry in
            BinDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bin Day NZ")
        .description("See your upcoming bin collection at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
