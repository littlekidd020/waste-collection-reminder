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

    /// Regular cycles only. One-off changes are property specific and are not shared.
    static func url(for zone: CollectionZone) -> URL? {
        guard zone.isValid else { return nil }
        let formatter = dayFormatter
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: "v", value: version)] + zone.schedules.map { schedule in
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

    /// Text for the share sheet: the link for people with the app, the store link for everyone else.
    static func shareText(for zone: CollectionZone) -> String? {
        guard let url = url(for: zone) else { return nil }
        return L("My Auckland bin schedule from Bin Day NZ. Open on iPhone to add it: %@", url.absoluteString)
            + "\n" + L("Get the app: %@", appStoreURL.absoluteString)
    }
}
