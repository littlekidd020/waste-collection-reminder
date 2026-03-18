# Bin Day NZ — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native SwiftUI iOS app that reminds New Zealanders about waste collection days, launching with Auckland Council data.

**Architecture:** SwiftUI app with SwiftData persistence, WidgetKit extension, UserNotifications for reminders, EventKit for calendar integration, and CloudKit for remote schedule updates. The core `ScheduleEngine` calculates collection dates from bundled JSON data.

**Tech Stack:** Swift, SwiftUI, SwiftData, WidgetKit, UserNotifications, EventKit, CloudKit, iOS 17+

---

## Task 1: Create Xcode Project & Data Models

**Files:**
- Create: `BinDayNZ/BinDayNZ.xcodeproj` (via Xcode CLI or manually)
- Create: `BinDayNZ/Models/BinType.swift`
- Create: `BinDayNZ/Models/Council.swift`
- Create: `BinDayNZ/Models/CollectionZone.swift`
- Create: `BinDayNZ/Models/CollectionSchedule.swift`
- Create: `BinDayNZ/Models/UserProfile.swift`

**Step 1: Create Xcode project skeleton**

The project should be created manually in Xcode with:
- Product Name: `BinDayNZ`
- Interface: SwiftUI
- Language: Swift
- Storage: SwiftData
- Include Widget Extension target: `BinDayNZWidget`
- Bundle ID: `com.bindaynz.app`

> [!IMPORTANT]
> This step requires Xcode. The developer should create the project via **Xcode → File → New → Project → iOS App**.

Alternatively, we can scaffold the file structure manually and have the developer open it in Xcode.

**Step 2: Create `BinType.swift`**

```swift
import Foundation
import SwiftUI

enum BinType: String, Codable, CaseIterable, Identifiable {
    case rubbish
    case recycling
    case foodScraps
    case inorganic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rubbish: return String(localized: "Rubbish")
        case .recycling: return String(localized: "Recycling")
        case .foodScraps: return String(localized: "Food Scraps")
        case .inorganic: return String(localized: "Inorganic Collection")
        }
    }

    var color: Color {
        switch self {
        case .rubbish: return .red
        case .recycling: return .yellow
        case .foodScraps: return .green
        case .inorganic: return .orange
        }
    }

    var icon: String {
        switch self {
        case .rubbish: return "🔴"
        case .recycling: return "🟡"
        case .foodScraps: return "🟢"
        case .inorganic: return "📦"
        }
    }
}
```

**Step 3: Create `Council.swift`**

```swift
import Foundation

struct Council: Codable, Identifiable {
    let id: UUID
    let name: String
    let region: String
    let binTypes: [BinType]
    let zones: [CollectionZone]
}
```

**Step 4: Create `CollectionZone.swift`**

```swift
import Foundation

struct CollectionZone: Codable, Identifiable {
    let id: UUID
    let name: String
    let suburbs: [String]
    let schedules: [CollectionSchedule]
}
```

**Step 5: Create `CollectionSchedule.swift`**

```swift
import Foundation

enum Frequency: String, Codable {
    case weekly
    case fortnightly
}

enum WeekPattern: String, Codable {
    case odd
    case even
}

struct CollectionSchedule: Codable, Identifiable {
    let id: UUID
    let binType: BinType
    let frequency: Frequency
    let dayOfWeek: Int // 1 = Monday ... 7 = Sunday
    let weekPattern: WeekPattern?
}
```

**Step 6: Create `UserProfile.swift`**

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    var councilId: UUID?
    var zoneId: UUID?
    var address: String?
    var notifyEveningBefore: Bool = true
    var eveningNotifyTime: Date = Calendar.current.date(from: DateComponents(hour: 19, minute: 0))!
    var notifyMorningOf: Bool = true
    var morningNotifyTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    var calendarSyncEnabled: Bool = false
    var language: String = "en"
    var hasCompletedOnboarding: Bool = false

    init() {}
}
```

**Step 7: Commit**

```bash
git add .
git commit -m "feat: add data models for Council, Zone, Schedule, BinType, and UserProfile"
```

---

## Task 2: Build the ScheduleEngine

**Files:**
- Create: `BinDayNZ/Services/ScheduleEngine.swift`
- Create: `BinDayNZTests/ScheduleEngineTests.swift`

**Step 1: Write tests for ScheduleEngine**

```swift
import XCTest
@testable import BinDayNZ

final class ScheduleEngineTests: XCTestCase {

    var engine: ScheduleEngine!
    var testZone: CollectionZone!

    override func setUp() {
        engine = ScheduleEngine()

        testZone = CollectionZone(
            id: UUID(),
            name: "Test Zone",
            suburbs: ["Ponsonby"],
            schedules: [
                CollectionSchedule(
                    id: UUID(),
                    binType: .rubbish,
                    frequency: .weekly,
                    dayOfWeek: 2, // Tuesday
                    weekPattern: nil
                ),
                CollectionSchedule(
                    id: UUID(),
                    binType: .recycling,
                    frequency: .fortnightly,
                    dayOfWeek: 2,
                    weekPattern: .even
                ),
                CollectionSchedule(
                    id: UUID(),
                    binType: .foodScraps,
                    frequency: .weekly,
                    dayOfWeek: 2,
                    weekPattern: nil
                )
            ]
        )
    }

    func testNextCollectionReturnsCorrectBinTypes() {
        let collections = engine.upcomingCollections(for: testZone, from: Date(), count: 5)
        XCTAssertFalse(collections.isEmpty)
    }

    func testWeeklyBinAppearsEveryWeek() {
        let collections = engine.upcomingCollections(for: testZone, from: Date(), count: 10)
        let rubbishDates = collections.filter { $0.binType == .rubbish }
        XCTAssertGreaterThanOrEqual(rubbishDates.count, 3)
    }

    func testFortnightlyBinAppearsEveryTwoWeeks() {
        let collections = engine.upcomingCollections(for: testZone, from: Date(), count: 20)
        let recyclingDates = collections.filter { $0.binType == .recycling }

        if recyclingDates.count >= 2 {
            let daysBetween = Calendar.current.dateComponents(
                [.day],
                from: recyclingDates[0].date,
                to: recyclingDates[1].date
            ).day!
            XCTAssertEqual(daysBetween, 14)
        }
    }

    func testIsCollectionDayReturnsTrueOnCorrectDay() {
        // Create a known Tuesday
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 17 // Tuesday
        let tuesday = Calendar.current.date(from: components)!

        let bins = engine.binsCollectedOn(date: tuesday, zone: testZone)
        XCTAssertTrue(bins.contains(.rubbish))
        XCTAssertTrue(bins.contains(.foodScraps))
    }
}
```

**Step 2: Run tests — expect FAIL (ScheduleEngine doesn't exist)**

```bash
xcodebuild test -scheme BinDayNZ -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Step 3: Implement ScheduleEngine**

```swift
import Foundation

struct UpcomingCollection: Identifiable {
    let id = UUID()
    let binType: BinType
    let date: Date
}

final class ScheduleEngine {

    func upcomingCollections(for zone: CollectionZone, from startDate: Date, count: Int) -> [UpcomingCollection] {
        var results: [UpcomingCollection] = []
        let calendar = Calendar.current

        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let bins = binsCollectedOn(date: date, zone: zone)
            for bin in bins {
                results.append(UpcomingCollection(binType: bin, date: date))
            }
            if results.count >= count { break }
        }

        return Array(results.prefix(count))
    }

    func binsCollectedOn(date: Date, zone: CollectionZone) -> [BinType] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Convert Sunday=1..Saturday=7 to Monday=1..Sunday=7
        let isoDayOfWeek = weekday == 1 ? 7 : weekday - 1

        return zone.schedules.compactMap { schedule in
            guard schedule.dayOfWeek == isoDayOfWeek else { return nil }

            switch schedule.frequency {
            case .weekly:
                return schedule.binType
            case .fortnightly:
                let weekOfYear = calendar.component(.weekOfYear, from: date)
                let isEvenWeek = weekOfYear % 2 == 0
                if let pattern = schedule.weekPattern {
                    if (pattern == .even && isEvenWeek) || (pattern == .odd && !isEvenWeek) {
                        return schedule.binType
                    }
                }
                return nil
            }
        }
    }

    func nextCollection(for zone: CollectionZone, from date: Date) -> UpcomingCollection? {
        return upcomingCollections(for: zone, from: date, count: 1).first
    }
}
```

**Step 4: Run tests — expect PASS**

```bash
xcodebuild test -scheme BinDayNZ -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Step 5: Commit**

```bash
git commit -am "feat: add ScheduleEngine with upcoming collection calculation"
```

---

## Task 3: Bundle Auckland Council Data

**Files:**
- Create: `BinDayNZ/Resources/councils.json`
- Create: `BinDayNZ/Services/DataService.swift`

**Step 1: Create `councils.json` with Auckland data**

This file contains Auckland Council's waste collection zones. The zone data should be sourced from Auckland Council's website.

```json
{
  "version": 1,
  "councils": [
    {
      "id": "auckland-council",
      "name": "Auckland Council",
      "region": "Auckland",
      "binTypes": ["rubbish", "recycling", "foodScraps", "inorganic"],
      "zones": [
        {
          "id": "auckland-zone-1-monday",
          "name": "Monday Collection",
          "suburbs": ["Ponsonby", "Grey Lynn", "Westmere", "Herne Bay"],
          "schedules": [
            { "id": "s1", "binType": "rubbish", "frequency": "weekly", "dayOfWeek": 1, "weekPattern": null },
            { "id": "s2", "binType": "recycling", "frequency": "fortnightly", "dayOfWeek": 1, "weekPattern": "even" },
            { "id": "s3", "binType": "foodScraps", "frequency": "weekly", "dayOfWeek": 1, "weekPattern": null }
          ]
        },
        {
          "id": "auckland-zone-2-tuesday",
          "name": "Tuesday Collection",
          "suburbs": ["Mt Eden", "Epsom", "Remuera", "Newmarket"],
          "schedules": [
            { "id": "s4", "binType": "rubbish", "frequency": "weekly", "dayOfWeek": 2, "weekPattern": null },
            { "id": "s5", "binType": "recycling", "frequency": "fortnightly", "dayOfWeek": 2, "weekPattern": "odd" },
            { "id": "s6", "binType": "foodScraps", "frequency": "weekly", "dayOfWeek": 2, "weekPattern": null }
          ]
        }
      ]
    }
  ]
}
```

> [!NOTE]
> More zones should be added with real Auckland Council data. This is a representative sample.

**Step 2: Create `DataService.swift`**

```swift
import Foundation

final class DataService {

    struct CouncilData: Codable {
        let version: Int
        let councils: [Council]
    }

    func loadBundledCouncils() -> [Council] {
        guard let url = Bundle.main.url(forResource: "councils", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let councilData = try? JSONDecoder().decode(CouncilData.self, from: data) else {
            return []
        }
        return councilData.councils
    }

    func findZone(for suburb: String, in council: Council) -> CollectionZone? {
        return council.zones.first { zone in
            zone.suburbs.contains { $0.localizedCaseInsensitiveCompare(suburb) == .orderedSame }
        }
    }

    func allSuburbs(for council: Council) -> [String] {
        return council.zones.flatMap { $0.suburbs }.sorted()
    }
}
```

**Step 3: Commit**

```bash
git commit -am "feat: add bundled Auckland council data and DataService"
```

---

## Task 4: Onboarding Views

**Files:**
- Create: `BinDayNZ/Views/Onboarding/WelcomeView.swift`
- Create: `BinDayNZ/Views/Onboarding/CouncilPickerView.swift`
- Create: `BinDayNZ/Views/Onboarding/AddressSearchView.swift`
- Create: `BinDayNZ/Views/Onboarding/ManualSetupView.swift`
- Create: `BinDayNZ/Views/Onboarding/NotificationSetupView.swift`
- Create: `BinDayNZ/Views/Onboarding/OnboardingContainerView.swift`

**Step 1: Build `OnboardingContainerView`** — a `TabView` with `.page` style wrapping all onboarding steps.

**Step 2: Build `WelcomeView`** — hero illustration with bin icons, app name, "Get Started" button, and language picker.

**Step 3: Build `CouncilPickerView`** — list of councils with supported ones tappable and unsupported greyed out with "Coming Soon" label.

**Step 4: Build `AddressSearchView`** — search field that filters suburbs. Tapping a suburb auto-selects the correct zone. "Set up manually" link at the bottom.

**Step 5: Build `ManualSetupView`** — day picker (Mon–Fri), bin type toggles, frequency picker.

**Step 6: Build `NotificationSetupView`** — toggles for evening/morning notifications with time pickers. Calendar sync toggle.

**Step 7: Commit**

```bash
git commit -am "feat: add onboarding flow views"
```

---

## Task 5: Today View (Home Screen)

**Files:**
- Create: `BinDayNZ/Views/Today/TodayView.swift`
- Create: `BinDayNZ/Views/Today/BinCard.swift`
- Create: `BinDayNZ/Views/Today/CountdownView.swift`

**Step 1: Build `BinCard`** — a colourful card showing bin icon, type name, and status ("Today" / "Tomorrow" / date). Background gradient matches bin colour.

**Step 2: Build `CountdownView`** — shows time until next collection with animated countdown.

**Step 3: Build `TodayView`** — hero section with today's bins (or "No collection today"), upcoming collections list, and countdown to next one.

**Step 4: Commit**

```bash
git commit -am "feat: add Today view with bin cards and countdown"
```

---

## Task 6: Schedule View (Calendar)

**Files:**
- Create: `BinDayNZ/Views/Schedule/ScheduleView.swift`
- Create: `BinDayNZ/Views/Schedule/CalendarMonthView.swift`
- Create: `BinDayNZ/Views/Schedule/DayDetailView.swift`

**Step 1: Build `CalendarMonthView`** — a custom month grid. Each day cell shows colour-coded dots for scheduled bin types.

**Step 2: Build `DayDetailView`** — sheet showing details for a tapped date: which bins, what goes in them.

**Step 3: Build `ScheduleView`** — month navigation (< Month Year >) wrapping CalendarMonthView, with a legend at the bottom.

**Step 4: Commit**

```bash
git commit -am "feat: add Schedule view with calendar and day detail"
```

---

## Task 7: Info View (Bin Guide)

**Files:**
- Create: `BinDayNZ/Views/Info/InfoView.swift`
- Create: `BinDayNZ/Views/Info/BinGuideView.swift`
- Create: `BinDayNZ/Views/Info/InorganicInfoView.swift`

**Step 1: Build `BinGuideView`** — expandable sections per bin type. Each shows ✅ accepted items and ❌ common mistakes.

**Step 2: Build `InorganicInfoView`** — info about inorganic collection events, booking links, accepted items.

**Step 3: Build `InfoView`** — navigation list with Bin Guide and Inorganic Collection sections.

**Step 4: Commit**

```bash
git commit -am "feat: add Info view with bin guide and inorganic info"
```

---

## Task 8: Settings View

**Files:**
- Create: `BinDayNZ/Views/Settings/SettingsView.swift`

**Step 1: Build `SettingsView`** — form with sections:
- **Address** — current address, change button (re-triggers address search)
- **Notifications** — toggles + time pickers for evening/morning
- **Calendar** — sync toggle, export `.ics` button
- **Language** — picker for supported languages
- **About** — app version, credits, link to Auckland Council website

**Step 2: Commit**

```bash
git commit -am "feat: add Settings view"
```

---

## Task 9: NotificationService

**Files:**
- Create: `BinDayNZ/Services/NotificationService.swift`

**Step 1: Implement `NotificationService`**

```swift
import UserNotifications

final class NotificationService {

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleCollectionReminder(
        binTypes: [BinType],
        collectionDate: Date,
        reminderTime: Date,
        isEvening: Bool
    ) {
        for bin in binTypes {
            let content = UNMutableNotificationContent()
            content.title = isEvening
                ? String(localized: "\(bin.icon) \(bin.displayName) bin out tonight!")
                : String(localized: "\(bin.icon) \(bin.displayName) day today!")
            content.body = isEvening
                ? String(localized: "Your \(bin.displayName.lowercased()) bin is collected tomorrow.")
                : String(localized: "Don't forget your \(bin.displayName.lowercased()) bin — collection is today.")
            content.sound = .default

            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderTime
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(bin.rawValue)-\(collectionDate.timeIntervalSince1970)-\(isEvening ? "eve" : "morn")",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func rescheduleUpcoming(zone: CollectionZone, profile: UserProfile, engine: ScheduleEngine) {
        cancelAllReminders()
        let upcoming = engine.upcomingCollections(for: zone, from: Date(), count: 30)

        for collection in upcoming {
            if profile.notifyEveningBefore {
                let eveningBefore = Calendar.current.date(byAdding: .day, value: -1, to: collection.date)!
                let reminderTime = combineDateAndTime(date: eveningBefore, time: profile.eveningNotifyTime)
                scheduleCollectionReminder(
                    binTypes: [collection.binType],
                    collectionDate: collection.date,
                    reminderTime: reminderTime,
                    isEvening: true
                )
            }
            if profile.notifyMorningOf {
                let reminderTime = combineDateAndTime(date: collection.date, time: profile.morningNotifyTime)
                scheduleCollectionReminder(
                    binTypes: [collection.binType],
                    collectionDate: collection.date,
                    reminderTime: reminderTime,
                    isEvening: false
                )
            }
        }
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combined = dateComponents
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? date
    }
}
```

**Step 2: Commit**

```bash
git commit -am "feat: add NotificationService for scheduling reminders"
```

---

## Task 10: CalendarService

**Files:**
- Create: `BinDayNZ/Services/CalendarService.swift`

**Step 1: Implement `CalendarService`** with EventKit integration for Apple Calendar and `.ics` file generation for Google Calendar export.

Key methods:
- `requestCalendarAccess() async -> Bool`
- `syncToAppleCalendar(zone:engine:)` — creates/updates "Bin Day NZ" calendar with colour-coded events
- `generateICSFile(zone:engine:) -> URL` — writes `.ics` file to temp directory for sharing

**Step 2: Commit**

```bash
git commit -am "feat: add CalendarService with EventKit and .ics export"
```

---

## Task 11: CloudKit Sync Service

**Files:**
- Create: `BinDayNZ/Services/CloudKitService.swift`

**Step 1: Implement `CloudKitService`** — checks a CloudKit public database for a `dataVersion` record. If the remote version is higher than the bundled version, downloads updated `councils.json`.

Key methods:
- `checkForUpdates() async -> Bool`
- `fetchUpdatedData() async -> CouncilData?`

> [!NOTE]
> CloudKit setup requires enabling the CloudKit capability in Xcode and configuring a container in the Apple Developer portal.

**Step 2: Commit**

```bash
git commit -am "feat: add CloudKitService for remote schedule updates"
```

---

## Task 12: Widget Extension

**Files:**
- Create: `BinDayNZWidget/BinDayNZWidget.swift`
- Create: `BinDayNZWidget/SmallWidgetView.swift`
- Create: `BinDayNZWidget/MediumWidgetView.swift`
- Create: `BinDayNZWidget/LockScreenWidgetView.swift`

**Step 1: Set up the widget entry and timeline provider** — `BinDayEntry` contains next collection info, `BinDayTimelineProvider` uses `ScheduleEngine` via App Groups shared data.

**Step 2: Build `SmallWidgetView`** — bin icon + colour background + date label.

**Step 3: Build `MediumWidgetView`** — row of next 3 collections with icons and dates.

**Step 4: Build `LockScreenWidgetView`** — compact inline text with bin icon.

**Step 5: Configure `WidgetBundle`** to register all three widget families.

> [!IMPORTANT]
> Widget and main app share data via App Groups. Must configure App Group capability in both targets.

**Step 6: Commit**

```bash
git commit -am "feat: add widget extension with small, medium, and lock screen widgets"
```

---

## Task 13: Localisation

**Files:**
- Create: `BinDayNZ/Resources/Localizable.xcstrings`

**Step 1: Extract all user-facing strings** using `String(localized:)` throughout the app.

**Step 2: Add Te Reo Māori translations.** Key translations:

| English | Te Reo Māori |
|---------|-------------|
| Rubbish | Para |
| Recycling | Hangarua |
| Food Scraps | Toenga Kai |
| Today | Tēnei Rā |
| Tomorrow | Āpōpō |
| Settings | Tautuhinga |

**Step 3: Commit**

```bash
git commit -am "feat: add Te Reo Māori localisation"
```

---

## Task 14: App Icon & Assets

**Files:**
- Modify: `BinDayNZ/Assets.xcassets`

**Step 1: Design app icon** — clean, friendly design featuring the three bin colours (red, yellow, green) on a white or dark background. Use a simple bin silhouette.

**Step 2: Create bin type icons** as SF Symbols or custom assets for use in the app and widget.

**Step 3: Add accent colors** for each bin type to the asset catalog.

**Step 4: Commit**

```bash
git commit -am "feat: add app icon and bin type assets"
```

---

## Verification Plan

### Automated Tests

```bash
# Run all unit tests
xcodebuild test -scheme BinDayNZ -destination 'platform=iOS Simulator,name=iPhone 16'
```

Tests cover:
- `ScheduleEngineTests` — collection date calculation, weekly/fortnightly logic
- `DataServiceTests` — JSON parsing, suburb lookup

### Manual Verification

> [!IMPORTANT]
> These steps require the app running on an iOS Simulator or physical device via Xcode.

1. **Build & run** — Open `BinDayNZ.xcodeproj` in Xcode, select iPhone 16 simulator, press ⌘R
2. **Onboarding flow** — Complete the full onboarding: select Auckland, search for "Ponsonby", verify correct zone assignment
3. **Today view** — Verify correct bins shown for today's date with correct colours
4. **Schedule view** — Navigate through months, verify colour-coded dots match expected collection days
5. **Notifications** — Go to Settings → enable notifications → check iOS notification center for scheduled reminders
6. **Widget** — Add Bin Day NZ widget to home screen, verify it shows correct next collection
7. **Calendar export** — Tap "Add to Calendar" in settings, verify events appear in Apple Calendar app
8. **Language switch** — Switch to Te Reo Māori in settings, verify all labels update correctly
9. **Offline mode** — Enable airplane mode, verify app still works with bundled data
