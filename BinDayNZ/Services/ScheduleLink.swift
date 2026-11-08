import Foundation

/// A schedule encoded in a `bindaynz://schedule` link. Households on one street share bin days,
/// so the schedule itself is the thing worth passing on. No server is involved; the recipient
/// still reviews and confirms before anything is saved.
enum ScheduleLink {
    static let scheme = "bindaynz"
    static let host = "schedule"
    static let appStoreURL = URL(string: "https://apps.apple.com/nz/app/bin-day-nz/id6761326182")!
    private static let version = "1"

    private static var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = ScheduleEngine.collectionCalendar
        formatter.timeZone = ScheduleEngine.collectionCalendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }

    /// Regular cycles only. One-off changes are property specific and are not shared; the council is.
    static func url(for zone: CollectionZone, council: Council? = nil) -> URL? {
        guard zone.isValid else { return nil }
        let formatter = dayFormatter
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: "v", value: version)]
            + (council.map { [URLQueryItem(name: "c", value: $0.id)] } ?? [])
            + zone.schedules.map { schedule in
            let cycle = schedule.frequency == .weekly ? "w" : "f"
            return URLQueryItem(name: "b", value: "\(schedule.binType.rawValue).\(cycle).\(formatter.string(from: schedule.anchorDate))")
        }
        return components.url
    }

    static func zone(from url: URL) -> CollectionZone? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == host,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              items.first(where: { $0.name == "v" })?.value == version else { return nil }
        let formatter = dayFormatter
        var schedules: [CollectionSchedule] = []
        for item in items where item.name == "b" {
            let parts = item.value?.split(separator: ".").map(String.init) ?? []
            guard parts.count == 3, let bin = BinType(rawValue: parts[0]), bin != .inorganic,
                  let frequency = parts[1] == "w" ? Frequency.weekly : parts[1] == "f" ? Frequency.fortnightly : nil,
                  let anchor = formatter.date(from: parts[2]) else { return nil }
            schedules.append(CollectionSchedule(id: bin.rawValue, binType: bin, frequency: frequency,
                                                anchorDate: ScheduleEngine.collectionCalendar.startOfDay(for: anchor)))
        }
        let zone = DataService.shared.manualZone(schedules: schedules)
        return zone.isValid ? zone : nil
    }

    /// The council named in a link, if it is one the app knows.
    static func council(from url: URL) -> Council? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == host,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return nil }
        return CouncilDirectory.council(id: items.first { $0.name == "c" }?.value)
    }

    /// Text for the share sheet. The schedule is spelled out first so the message is useful on any phone;
    /// the app link follows for iPhone, then the store link for everyone else.
    static func shareText(for zone: CollectionZone, council: Council?, now: Date = Date()) -> String? {
        guard let url = url(for: zone, council: council) else { return nil }
        let heading = council.map { L("My bin schedule from Bin Day NZ (%@):", $0.name) } ?? L("My bin schedule from Bin Day NZ:")
        let lines = [heading] + scheduleLines(for: zone, now: now)
            + [L("Open on iPhone to add it: %@", url.absoluteString), L("Get the app: %@", appStoreURL.absoluteString)]
        return lines.joined(separator: "\n")
    }

    /// One plain-language line per bin, in the app's language: "Recycling: every second Tuesday, next 11 Nov".
    static func scheduleLines(for zone: CollectionZone, now: Date = Date()) -> [String] {
        let engine = ScheduleEngine()
        let language = LanguageManager.shared.currentCode
        let weekday = CollectionDateFormatters.shared.formatter(template: "EEEE", languageCode: language)
        let short = CollectionDateFormatters.shared.formatter(template: "d MMM", languageCode: language)
        return zone.schedules.map { schedule in
            let day = weekday.string(from: schedule.anchorDate)
            switch schedule.frequency {
            case .weekly:
                return L("%@: every %@", schedule.binType.displayName, day)
            case .fortnightly:
                let single = CollectionZone(id: zone.id, name: zone.name, suburbs: [], schedules: [schedule])
                guard let next = engine.upcomingCollections(for: single, from: now, count: 1).first else {
                    return L("%@: every second %@", schedule.binType.displayName, day)
                }
                return L("%@: every second %@, next %@", schedule.binType.displayName, day, short.string(from: next.date))
            }
        }
    }
}
