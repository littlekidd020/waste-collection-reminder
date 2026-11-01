import Foundation

// Read-only localization substitutes avoid changing AppleLanguages in the host's defaults.
// ScheduleEngine and all collection models below are compiled from production source.
func L(_ key: String, _ args: CVarArg...) -> String { key }
enum LanguageManager {
    static let shared = AuditLanguage()
    struct AuditLanguage { let locale = Locale(identifier: "en_NZ") }
}

var failed = 0
var checked = 0
func check(_ name: String, _ condition: Bool, _ detail: String) {
    checked += 1
    if !condition { failed += 1 }
    print("\(condition ? "PASS" : "FAIL") \(name): \(detail)")
}

func calendar(_ locale: String = "en_NZ", zone: String = "Pacific/Auckland", iso: Bool = false) -> Calendar {
    var value = Calendar(identifier: iso ? .iso8601 : .gregorian)
    value.locale = Locale(identifier: locale)
    value.timeZone = TimeZone(identifier: zone)!
    return value
}

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0, in cal: Calendar) -> Date {
    cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

func label(_ value: Date, in cal: Calendar) -> String {
    let parts = cal.dateComponents([.year, .month, .day], from: value)
    return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
}

func zone(_ pattern: WeekPattern?, day: Int = 1) -> CollectionZone {
    CollectionZone(id: "audit", name: "Audit", suburbs: [], schedules: [
        CollectionSchedule(id: "audit-recycling", binType: .recycling,
                           frequency: pattern == nil ? .weekly : .fortnightly,
                           dayOfWeek: day, weekPattern: pattern)
    ])
}

let nz = calendar(iso: true)
let nzEngine = ScheduleEngine(calendar: nz)
print("BinDayNZ deterministic reliability audit — fixed dates, host Foundation; no notifications/calendar/widget process invoked")

// Invariant: consecutive fortnightly dates must always be 14 local calendar days apart.
for pattern in [WeekPattern.odd, .even] {
    let dates = nzEngine.upcomingCollections(for: zone(pattern), from: date(2026, 12, 14, in: nz), count: 5).map(\.date)
    let gaps = zip(dates, dates.dropFirst()).map { nz.dateComponents([.day], from: $0, to: $1).day! }
    check("fortnightly-\(pattern.rawValue)-year-rollover", gaps.allSatisfy { $0 == 14 },
          "dates=\(dates.map { label($0, in: nz) }); gaps=\(gaps) days")
}

// Calendar.locale controls week rules; identical NZ property dates must not change bins with device locale.
let localeNZ = calendar("en_NZ")
let localeUS = calendar("en_US")
let localeGB = calendar("en_GB")
let localeDate = date(2027, 1, 4, in: localeNZ)
let nzBins = ScheduleEngine(calendar: localeNZ).binsCollectedOn(date: localeDate, zone: zone(.odd))
let usBins = ScheduleEngine(calendar: localeUS).binsCollectedOn(date: localeDate, zone: zone(.odd))
let gbBins = ScheduleEngine(calendar: localeGB).binsCollectedOn(date: localeDate, zone: zone(.odd))
check("device-locale-independence", nzBins == usBins && nzBins == gbBins,
      "2027-01-04: NZ week=\(localeNZ.component(.weekOfYear, from: localeDate)), firstWeekday=\(localeNZ.firstWeekday), minimumDays=\(localeNZ.minimumDaysInFirstWeek), bins=\(nzBins.map(\.rawValue)); US week=\(localeUS.component(.weekOfYear, from: localeDate)), firstWeekday=\(localeUS.firstWeekday), minimumDays=\(localeUS.minimumDaysInFirstWeek), bins=\(usBins.map(\.rawValue)); GB week=\(localeGB.component(.weekOfYear, from: localeDate)), firstWeekday=\(localeGB.firstWeekday), minimumDays=\(localeGB.minimumDaysInFirstWeek), bins=\(gbBins.map(\.rawValue))")

for pattern in [WeekPattern.odd, .even] {
    let dates = ScheduleEngine(calendar: localeNZ).upcomingCollections(for: zone(pattern), from: date(2028, 12, 11, in: localeNZ), count: 5).map(\.date)
    let gaps = zip(dates, dates.dropFirst()).map { localeNZ.dateComponents([.day], from: $0, to: $1).day! }
    check("NZ-calendar-fortnightly-\(pattern.rawValue)-year-rollover", gaps.allSatisfy { $0 == 14 },
          "dates=\(dates.map { label($0, in: localeNZ) }); gaps=\(gaps) days")
}

// Weekly scheduling correctly uses local calendar days, rather than fixed 24-hour arithmetic.
for (name, start) in [("DST-end", date(2026, 3, 30, in: nz)), ("DST-start", date(2026, 9, 21, in: nz))] {
    let dates = nzEngine.upcomingCollections(for: zone(nil), from: start, count: 2).map(\.date)
    let dayGap = nz.dateComponents([.day], from: dates[0], to: dates[1]).day!
    let elapsedHours = dates[1].timeIntervalSince(dates[0]) / 3600
    check(name, dayGap == 7 && dates.allSatisfy { nz.component(.hour, from: $0) == 0 },
          "dates=\(dates.map { label($0, in: nz) }); calendar gap=\(dayGap) days; elapsed=\(elapsedHours) hours; midnight preserved")
}

// Property timezone assumption: a NZ property's collection-day classification stays anchored to NZ.
let la = calendar("en_NZ", zone: "America/Los_Angeles", iso: true)
let instant = date(2026, 9, 7, hour: 0, minute: 30, in: nz)
let homeBins = nzEngine.binsCollectedOn(date: instant, zone: zone(nil))
let travelBins = ScheduleEngine(calendar: la).binsCollectedOn(date: instant, zone: zone(nil))
check("property-timezone-independence", homeBins == travelBins,
      "same instant is NZ \(label(instant, in: nz)) / LA \(label(instant, in: la)); NZ bins=\(homeBins.map(\.rawValue)); LA bins=\(travelBins.map(\.rawValue)); product must define home-vs-device timezone policy")

struct BundledData: Decodable { let version: Int; let councils: [Council] }
let bundled = try JSONDecoder().decode(BundledData.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
let aucklandMonday = bundled.councils.first { $0.id == "auckland-council" }!.zones.first { $0.id == "akl-zone-mon" }!
let snapshotStart = date(2026, 9, 6, hour: 12, in: nz)

// Exact window/filter policy from WidgetDataService:15-18 and BinDayNZWidget:104-108.
// This evaluates stored-payload lifetime, not WidgetKit's scheduling/rendering behavior.
let stored = nzEngine.upcomingCollections(for: aucklandMonday, from: snapshotStart, count: 12)
let expiration = nz.date(byAdding: .day, value: 1, to: stored.last!.date)!
let remaining = stored.filter { $0.date >= nz.startOfDay(for: expiration) }
let actualUpcoming = nzEngine.upcomingCollections(for: aucklandMonday, from: expiration, count: 3)
check("widget-payload-covers-ongoing-schedule", !remaining.isEmpty || actualUpcoming.isEmpty,
      "snapshot 2026-09-06 has \(stored.count) bin events; last stored=\(label(stored.last!.date, in: nz)); on \(label(expiration, in: nz)) stored future=\(remaining.count), actual future=\(actualUpcoming.count); next actual=\(label(actualUpcoming[0].date, in: nz))")

// Data-generation count only: no UNUserNotificationCenter calls or assertion about modern OS retention.
let notificationCollections = nzEngine.upcomingCollections(for: aucklandMonday, from: snapshotStart, count: 60)
let generatedReminderCount = notificationCollections.reduce(0) { count, collection in
    let evening = nz.date(bySettingHour: 19, minute: 0, second: 0, of: nz.date(byAdding: .day, value: -1, to: collection.date)!)!
    let morning = nz.date(bySettingHour: 7, minute: 0, second: 0, of: collection.date)!
    return count + (evening > snapshotStart ? 1 : 0) + (morning > snapshotStart ? 1 : 0)
}
print("OBSERVATION notification-generation: \(notificationCollections.count) collection entries generate \(generatedReminderCount) one-shot requests; last collection=\(label(notificationCollections.last!.date, in: nz)); current-OS pending retention NOT tested")
print("RESULT \(checked - failed)/\(checked) desired invariants pass; \(failed) failures reproduced. Exit status 1 indicates failed invariants.")
exit(failed == 0 ? 0 : 1)
