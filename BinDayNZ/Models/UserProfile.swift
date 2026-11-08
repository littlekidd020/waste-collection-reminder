import Foundation
import SwiftData

/// Supported app languages.
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case teReoMaori = "mi"
    case simplifiedChinese = "zh-Hans"
    case hindi = "hi"
    case korean = "ko"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .teReoMaori: return "Te Reo Māori"
        case .simplifiedChinese: return "简体中文"
        case .hindi: return "हिन्दी"
        case .korean: return "한국어"
        }
    }

    /// The app language matching the device's language settings, or English when the device
    /// uses none of the languages the app ships.
    static var deviceDefault: AppLanguage { preferred(from: Locale.preferredLanguages) }

    /// Picks the best app language for an ordered list of language preferences (e.g. ["zh-CN", "en-NZ"]),
    /// using the same matching the system applies to app bundles, so regional variants and
    /// Chinese scripts resolve to the shipped localization.
    static func preferred(from preferences: [String]) -> AppLanguage {
        let shipped = allCases.map(\.rawValue)
        let best = Bundle.preferredLocalizations(from: shipped, forPreferences: preferences).first
        return best.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}

/// The user's saved preferences and setup, persisted with SwiftData.
@Model
final class UserProfile {
    var councilId: String?
    var zoneId: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var manualSchedulesJSON: String?
    var scheduleConfirmedAt: Date?
    var remindersScheduledThrough: Date?
    var integrationMessage: String?

    // Notification preferences
    var notifyEveningBefore: Bool = true
    var eveningNotifyHour: Int = 19
    var eveningNotifyMinute: Int = 0
    var notifyMorningOf: Bool = true
    var morningNotifyHour: Int = 7
    var morningNotifyMinute: Int = 0
    var notifyBringIn: Bool = false
    var bringInNotifyHour: Int = 18
    var bringInNotifyMinute: Int = 0
    /// Reminders are silenced for collections up to and including this day; nil when not away.
    var remindersPausedUntil: Date?
    /// The collection day whose bins the household has already put out at the kerb. Its evening and
    /// morning reminders are skipped. Cleared automatically once that day has passed.
    var binsOutForCollectionOn: Date?

    // Calendar
    var calendarSyncEnabled: Bool = false
    var calendarRemindersEnabled: Bool = false

    // Language. The stored default stays English for existing rows; new profiles follow the device language.
    var languageCode: String = AppLanguage.english.rawValue

    // Onboarding
    var hasCompletedOnboarding: Bool = false

    init() {
        languageCode = AppLanguage.deviceDefault.rawValue
    }

    // MARK: - Computed Properties

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageCode) ?? .english }
        set { languageCode = newValue.rawValue }
    }

    var eveningNotifyTime: Date {
        get {
            ScheduleEngine.collectionCalendar.date(from: DateComponents(hour: eveningNotifyHour, minute: eveningNotifyMinute)) ?? Date()
        }
        set {
            let components = ScheduleEngine.collectionCalendar.dateComponents([.hour, .minute], from: newValue)
            eveningNotifyHour = components.hour ?? 19
            eveningNotifyMinute = components.minute ?? 0
        }
    }

    var morningNotifyTime: Date {
        get {
            ScheduleEngine.collectionCalendar.date(from: DateComponents(hour: morningNotifyHour, minute: morningNotifyMinute)) ?? Date()
        }
        set {
            let components = ScheduleEngine.collectionCalendar.dateComponents([.hour, .minute], from: newValue)
            morningNotifyHour = components.hour ?? 7
            morningNotifyMinute = components.minute ?? 0
        }
    }

    var bringInNotifyTime: Date {
        get {
            ScheduleEngine.collectionCalendar.date(from: DateComponents(hour: bringInNotifyHour, minute: bringInNotifyMinute)) ?? Date()
        }
        set {
            let components = ScheduleEngine.collectionCalendar.dateComponents([.hour, .minute], from: newValue)
            bringInNotifyHour = components.hour ?? 18
            bringInNotifyMinute = components.minute ?? 0
        }
    }
}
