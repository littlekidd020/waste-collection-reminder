import Foundation

/// Dates in the collection views always describe the property's New Zealand day.
/// Formatters are cached per template and language; the month grid asks for dozens per render.
func collectionDateLabel(_ date: Date, template: String = "EEEE d MMMM") -> String {
    CollectionDateFormatters.shared.formatter(template: template, languageCode: LanguageManager.shared.currentCode).string(from: date)
}

final class CollectionDateFormatters {
    static let shared = CollectionDateFormatters()
    private let lock = NSLock()
    private var formatters: [String: DateFormatter] = [:]

    func formatter(template: String, languageCode: String) -> DateFormatter {
        let key = languageCode + "|" + template
        lock.lock(); defer { lock.unlock() }
        if let formatter = formatters[key] { return formatter }
        let formatter = DateFormatter()
        formatter.calendar = ScheduleEngine.collectionCalendar
        formatter.timeZone = ScheduleEngine.collectionCalendar.timeZone
        formatter.locale = Locale.app(languageCode)
        formatter.setLocalizedDateFormatFromTemplate(template)
        formatters[key] = formatter
        return formatter
    }
}
