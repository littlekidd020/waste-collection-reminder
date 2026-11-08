import Foundation

/// The words on Today, derived from the next collection and the clock. Pure, so it can be tested.
enum TodayCopy {
    enum Phase: Equatable {
        /// The collection is today; `morning` while the trucks may still be coming.
        case collectionDay(morning: Bool)
        /// The collection is tomorrow: bins go out tonight.
        case tonight
        /// The collection is two or more days away.
        case later(days: Int)

        /// Whether the household can sensibly mark the bins as out at the kerb.
        var allowsKerb: Bool {
            if case .later = self { return false }
            return true
        }
    }

    static func phase(now: Date, next: Date) -> Phase {
        let calendar = ScheduleEngine.collectionCalendar
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: next)).day ?? 0
        if days <= 0 { return .collectionDay(morning: calendar.component(.hour, from: now) < 12) }
        if days == 1 { return .tonight }
        return .later(days: days)
    }

    static func relative(_ phase: Phase) -> String {
        switch phase {
        case .collectionDay: return L("Today")
        case .tonight: return L("Tomorrow")
        case .later(let days): return L("In %d days", days)
        }
    }

    /// "Tomorrow · Tuesday 10 November"
    static func eyebrow(phase: Phase, date: Date) -> String {
        relative(phase) + " · " + plainDate(date)
    }

    /// The full date without the comma English formatters put after the weekday, so small caps read
    /// as one phrase: "Tuesday 10 November". Other languages keep their own punctuation.
    static func plainDate(_ date: Date, template: String = "EEEE d MMMM") -> String {
        let label = collectionDateLabel(date, template: template)
        return LanguageManager.shared.currentCode == "en" ? label.replacingOccurrences(of: ",", with: "") : label
    }

    static func verdict(phase: Phase, atKerb: Bool) -> String {
        if atKerb { return L("Done for tonight") }
        switch phase {
        case .collectionDay: return L("Collection today")
        case .tonight: return L("Out tonight")
        case .later: return L("Nothing tonight")
        }
    }

    static func sentence(phase: Phase, atKerb: Bool, bins: [BinType], date: Date) -> String {
        if atKerb { return L("They are at the kerb. Reminders for this collection are off.") }
        let names = list(bins)
        switch phase {
        case .collectionDay(let morning):
            return morning ? L("%@. Have them out early.", names) : L("%@. Bring them in once they are emptied.", names)
        case .tonight:
            return L("%@. Put them out tonight.", names)
        case .later:
            return L("Next: %@ on %@.", names, collectionDateLabel(date, template: "EEEE"))
        }
    }

    /// The collection after the next one, so the fortnight rhythm is always in view.
    static func following(date: Date, bins: [BinType]) -> String {
        L("Then %@: %@.", plainDate(date), list(bins))
    }

    /// "Recycling, rubbish and food scraps": the display names joined for the language, the first
    /// capitalised. English follows New Zealand usage with no serial comma; te reo Māori joins with "me".
    static func list(_ bins: [BinType]) -> String {
        let locale = LanguageManager.shared.locale
        let code = LanguageManager.shared.currentCode
        let lowers = code == "en" || code == "mi"
        let names = bins.map(\.displayName).enumerated().map { index, name in
            index > 0 && lowers ? name.lowercased(with: locale) : name
        }
        switch code {
        case "en": return joined(names, and: "and")
        case "mi": return joined(names, and: "me")
        default:
            let formatter = ListFormatter()
            formatter.locale = locale
            return formatter.string(from: names) ?? names.joined(separator: ", ")
        }
    }

    private static func joined(_ names: [String], and word: String) -> String {
        guard names.count > 1, let last = names.last else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " " + word + " " + last
    }

    /// "7 pm and 7 am": the enabled reminder times in the language.
    static func reminderTimes(_ preferences: ReminderPreferences) -> String {
        let calendar = ScheduleEngine.collectionCalendar
        let locale = LanguageManager.shared.locale
        var times: [String] = []
        func add(_ hour: Int, _ minute: Int) {
            guard let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour, minute: minute)) else { return }
            var style = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            if minute == 0 { style = style.hour(.defaultDigits(amPM: .abbreviated)) }
            times.append(date.formatted(style))
        }
        if preferences.evening { add(preferences.eveningHour, preferences.eveningMinute) }
        if preferences.morning { add(preferences.morningHour, preferences.morningMinute) }
        if preferences.bringIn { add(preferences.bringInHour, preferences.bringInMinute) }
        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: times) ?? times.joined(separator: ", ")
    }

    /// The suburb from a saved address, for the location capsule: "14 Valley Road, Mount Eden, Auckland" gives "Mount Eden".
    static func shortAddress(_ address: String?) -> String? {
        guard let address else { return nil }
        let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard let first = parts.first else { return nil }
        if parts.count >= 2 {
            let second = parts[1]
            // drop a postcode or region suffix such as "Auckland 1024"
            let words = second.split(separator: " ").filter { Int($0) == nil }
            if !words.isEmpty { return words.joined(separator: " ") }
        }
        return first
    }
}
