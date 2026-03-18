# Bin Day NZ — App Design

> A free, native SwiftUI iOS app that reminds New Zealanders when to put their bins out.
> Phased rollout starting with Auckland, expanding council by council.

---

## Overview

**Bin Day NZ** covers:
- 🔴 **Red bin** — General rubbish
- 🟡 **Yellow bin** — Recycling
- 🟢 **Green bin** — Food scraps
- 📦 **Inorganic collection** — Special large item events

**Key features:**
- Push notifications (evening before + morning of)
- iOS home screen & lock screen widgets
- Apple Calendar integration + `.ics` export for Google Calendar
- Multi-language support
- Offline-first with CloudKit remote updates
- Completely free — a community service app

---

## Architecture

```
┌─────────────────────────────────────────┐
│              SwiftUI App                │
│  ┌───────────┬───────────┬───────────┐  │
│  │  Onboard  │   Home    │ Settings  │  │
│  │  Flow     │   View    │   View    │  │
│  └───────────┴───────────┴───────────┘  │
│  ┌───────────────────────────────────┐  │
│  │     iOS Widget Extension          │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │     Notification Service          │  │
│  └───────────────────────────────────┘  │
├─────────────────────────────────────────┤
│  Local Data Layer (SwiftData)           │
│  + CloudKit for remote updates          │
├─────────────────────────────────────────┤
│  Bundled Schedule Dataset (JSON)        │
└─────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (iOS 17+) |
| Data | SwiftData + CloudKit |
| Notifications | UserNotifications framework |
| Widget | WidgetKit (small, medium, lock screen) |
| Calendar | EventKit + `.ics` export |
| Localisation | Xcode String Catalogs (`.xcstrings`) |
| Min target | iOS 17.0 |

---

## Screens & User Flow

### Onboarding (first launch)

1. **Welcome** — App intro with bin illustrations, language selector
2. **Select your council** — Picker showing supported councils (Auckland at launch, "coming soon" for others)
3. **Find your address** — Search with autocomplete → auto-assign schedule. Falls back to manual setup
4. **Manual fallback** — Pick collection day (Mon–Fri), bin types, frequency (weekly/fortnightly)
5. **Notification preferences** — Evening before (default 7pm), morning of (default 7am), or both. Customisable time
6. **Calendar sync prompt** — Add to Apple Calendar or export `.ics` for Google Calendar
7. **Done!** — Show home screen with next collection

### Main Screens (Tab Bar)

- **Today** — Hero card showing what's collected today/tomorrow with colourful bin icons. Countdown to next collection
- **Schedule** — Monthly calendar view with colour-coded dots per bin type. Tap a date for details
- **Info** — What goes in each bin (examples & common mistakes), inorganic collection info
- **Settings** — Change address, notification times, language, calendar sync, about/credits

---

## Widget & Notifications

### iOS Home Screen Widget (WidgetKit)

**Small (2×2)**
- Next bin type with colour icon
- Collection day label ("Tomorrow" / "Wed 20 Mar")
- Background tinted to bin colour

**Medium (4×2)**
- Next 2–3 upcoming collections in a row
- Each with bin colour icon + date
- "Today"/"Tomorrow" labels highlighted

**Lock Screen**
- Compact circular icon showing next bin colour
- Inline text: "🟡 Recycling tomorrow"

### Push Notifications

**Evening before (default 7:00 PM)**
> 🟡 Recycling bin out tonight!
> Your yellow recycling bin is collected tomorrow, Wednesday 20 Mar.

**Morning of (default 7:00 AM)**
> 🔴 Rubbish day today!
> Don't forget your red bin — collection is today.

**Inorganic collection (1 week before + day before)**
> 📦 Inorganic collection coming up!
> Book your spot by 18 Mar. Items collected 25 Mar.

### Calendar Integration

- **Apple Calendar** — Direct EventKit integration. Repeating calendar "Bin Day NZ" with colour-coded events
- **Google Calendar / Other** — `.ics` subscription URL. User adds once, stays in sync
- Events include bin type in title + "what goes in this bin" note in description

---

## Data Model (SwiftData)

```swift
// Council — represents a territorial authority
Council
├── id: UUID
├── name: String              // "Auckland Council"
├── region: String            // "Auckland"
├── binTypes: [BinType]
└── zones: [CollectionZone]

// Zone — a collection area within a council
CollectionZone
├── id: UUID
├── name: String              // "Zone A - Monday"
├── suburbs: [String]         // ["Ponsonby", "Grey Lynn", ...]
└── schedules: [CollectionSchedule]

// Schedule — when a specific bin type is collected
CollectionSchedule
├── binType: BinType          // .rubbish, .recycling, .foodScraps
├── frequency: Frequency      // .weekly, .fortnightly
├── dayOfWeek: Int            // 1=Mon ... 5=Fri
└── weekPattern: WeekPattern? // For fortnightly: .odd / .even

// Bin types
BinType (enum)
├── rubbish      → 🔴 Red
├── recycling    → 🟡 Yellow
├── foodScraps   → 🟢 Green
└── inorganic    → 📦 Special

// User's saved preferences
UserProfile
├── councilId: UUID
├── zoneId: UUID
├── address: String?
├── notifyEveningBefore: Bool + Time
├── notifyMorningOf: Bool + Time
├── calendarSyncEnabled: Bool
└── language: AppLanguage
```

### Bundled Data
- Ship as `councils.json` in the app bundle
- CloudKit stores a `dataVersion` integer — app checks on launch, pulls updated JSON if newer
- App works fully offline

---

## Localisation

- **Launch languages:** English, Te Reo Māori
- **Future languages:** Simplified Chinese, Hindi, Korean
- Xcode String Catalogs (`.xcstrings`) for all UI text
- Bin type names and "what goes in" content also localised
- Date formatting uses device locale automatically

---

## Rollout Plan

### Phase 1 — MVP (Auckland)
- ✅ Onboarding with Auckland zones
- ✅ Push notifications (evening + morning)
- ✅ Home screen widget (small + medium + lock screen)
- ✅ Calendar integration (Apple + `.ics`)
- ✅ English + Te Reo Māori
- ✅ Offline-first with CloudKit sync

### Phase 2 — Major Cities
- Wellington, Christchurch, Hamilton

### Phase 3 — Expansion
- Remaining major cities (Tauranga, Dunedin, etc.)

### Phase 4 — National Coverage
- Community submissions for smaller councils

### Phase 5 — Full Localisation
- Simplified Chinese, Hindi, Korean

---

## Project Structure

```
BinDayNZ/
├── App/
│   ├── BinDayNZApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Council.swift
│   ├── CollectionZone.swift
│   ├── CollectionSchedule.swift
│   ├── BinType.swift
│   └── UserProfile.swift
├── Views/
│   ├── Onboarding/
│   ├── Today/
│   ├── Schedule/
│   ├── Info/
│   └── Settings/
├── Services/
│   ├── NotificationService.swift
│   ├── CalendarService.swift
│   ├── CloudKitService.swift
│   └── ScheduleEngine.swift
├── Resources/
│   ├── councils.json
│   └── Localizable.xcstrings
├── BinDayNZWidget/
│   ├── BinDayNZWidget.swift
│   ├── SmallWidgetView.swift
│   ├── MediumWidgetView.swift
│   └── LockScreenWidgetView.swift
└── Assets.xcassets
```
