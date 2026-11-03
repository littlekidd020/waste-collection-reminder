import Foundation
import SwiftUI

/// Manages runtime language switching by loading the correct .lproj bundle.
/// Use the global `L(_:)` function to get localized strings.
@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    /// The currently active language bundle (e.g. mi.lproj)
    private(set) var bundle: Bundle = .main

    /// Current language code
    private(set) var currentCode: String = "en"

    /// The Locale matching the current language (e.g. for DateFormatters)
    var locale: Locale { Locale.app(currentCode) }

    private init() {
        // On first load, check if user had a saved preference
        if let saved = UserDefaults.standard.string(forKey: "appLanguageCode") {
            apply(saved)
        }
    }

    /// Switch to a new language. Updates the bundle immediately.
    func apply(_ code: String) {
        currentCode = code
        UserDefaults.standard.set(code, forKey: "appLanguageCode")

        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            // Fallback to main (English)
            bundle = .main
        }
    }
}

extension Locale {
    /// The locale for an app language. Plain "en" formats dates the American way ("November 18"),
    /// so English uses the New Zealand region; the other languages already order day before month.
    static func app(_ languageCode: String) -> Locale {
        Locale(identifier: languageCode == "en" ? "en_NZ" : languageCode)
    }
}

/// Global shortcut for getting a localized string using the current language bundle.
/// Usage: `L("Today")` instead of `String(localized: "Today")`
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, bundle: LanguageManager.shared.bundle, comment: "")
    if args.isEmpty {
        return format
    }
    // Apple uses numbered format specifiers natively, but this handles basic %@ formatting safely
    return String(format: format, locale: LanguageManager.shared.locale, arguments: args)
}
