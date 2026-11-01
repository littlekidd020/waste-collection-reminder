import Foundation
import EventKit
import CoreGraphics

/// Owns only marked events in the calendar whose identifier this install saved.
@MainActor
final class CalendarService {
    static let shared = CalendarService()
    private static let ownershipKey = "BinDayNZ.calendarOwnership"
    private let eventStore: EKEventStore
    private let defaults: UserDefaults
    private var isUpdating = false

    init(eventStore: EKEventStore = EKEventStore(), defaults: UserDefaults = .standard) {
        self.eventStore = eventStore
        self.defaults = defaults
    }

    private struct Ownership: Codable {
        let calendarIdentifier: String
        let token: String
        var itemIdentifiers: [String]
        var needsCleanup: Bool
        var searchStart: Date
        var searchEnd: Date
    }

    struct PlannedEvent {
        let key: String
        let binType: BinType
        let start: Date
        let end: Date
        let intervalWeeks: Int?
        let recurrenceEnd: Date?
        let isReminder: Bool
    }

    func requestAccess() async -> Bool {
        do { return try await eventStore.requestFullAccessToEvents() }
        catch { return false }
    }

    /// Offsets represent NZ wall-clock times relative to collection midnight.
    /// -5 hours is 19:00 the previous day; +7 hours is 07:00 that day.
    /// Separate timed reminder events preserve the chosen time through DST.
    func syncToAppleCalendar(zone: CollectionZone, reminderOffsets: [TimeInterval] = []) async throws {
        guard !isUpdating else { throw CalendarError.updateInProgress }
        isUpdating = true
        defer { isUpdating = false }
        let plans = try Self.plannedEvents(zone: zone, reminderOffsets: reminderOffsets)
        guard await requestAccess() else { throw CalendarError.accessDenied }
        do {
            var ownership = try findOrCreateOwnedCalendar()
            guard let calendar = eventStore.calendar(withIdentifier: ownership.calendarIdentifier),
                  calendar.allowsContentModifications else { throw CalendarError.calendarUnavailable }
            let previousEvents = try ownedEvents(ownership)

            // Persist bounds first so a commit interrupted before identifier persistence is recoverable.
            ownership.searchStart = min(ownership.searchStart, plans.map(\.start).min()!)
            ownership.searchEnd = max(ownership.searchEnd, plans.map(\.end).max()!)
            ownership.needsCleanup = true
            try saveOwnership(ownership)

            var replacements: [EKEvent] = []
            for plan in plans {
                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = plan.isReminder
                    ? L("Reminder: %@", plan.binType.displayName)
                    : "\(plan.binType.icon) \(plan.binType.displayName)"
                event.notes = plan.binType.acceptedItems.joined(separator: "\n")
                event.url = Self.ownershipMarker(token: ownership.token, eventKey: plan.key)
                event.timeZone = ScheduleEngine.collectionCalendar.timeZone
                event.startDate = plan.start
                event.endDate = plan.end
                event.isAllDay = !plan.isReminder
                event.availability = .free
                if let interval = plan.intervalWeeks {
                    event.recurrenceRules = [EKRecurrenceRule(
                        recurrenceWith: .weekly, interval: interval,
                        end: plan.recurrenceEnd.map { EKRecurrenceEnd(end: $0) }
                    )]
                }
                event.alarms = plan.isReminder ? [EKAlarm(relativeOffset: 0)] : []
                try eventStore.save(event, span: .futureEvents, commit: false)
                replacements.append(event)
            }
            for event in previousEvents {
                try eventStore.remove(event, span: .futureEvents, commit: false)
            }
            try eventStore.commit()
            ownership.itemIdentifiers = replacements.map(\.calendarItemIdentifier)
            try saveOwnership(ownership)
        } catch {
            eventStore.reset()
            if let error = error as? CalendarError { throw error }
            throw CalendarError.updateFailed
        }
    }

    /// Disabling sync removes our events, never the calendar or unrelated events.
    func removeSyncedCalendar() throws {
        guard !isUpdating else { throw CalendarError.updateInProgress }
        guard var ownership = try loadOwnership() else { return }
        guard ownership.needsCleanup else { return }
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw CalendarError.accessDenied
        }
        isUpdating = true
        defer { isUpdating = false }
        do {
            for event in try ownedEvents(ownership) {
                try eventStore.remove(event, span: .futureEvents, commit: false)
            }
            try eventStore.commit()
            ownership.itemIdentifiers = []
            ownership.needsCleanup = false
            try saveOwnership(ownership)
        } catch {
            eventStore.reset()
            if let error = error as? CalendarError { throw error }
            throw CalendarError.updateFailed
        }
    }

    /// Explicit local-only deletion may abandon tracking after its residual-event warning.
    /// This never deletes or edits a calendar or event.
    func forgetConnection() {
        defaults.removeObject(forKey: Self.ownershipKey)
    }

    private func findOrCreateOwnedCalendar() throws -> Ownership {
        if let ownership = try loadOwnership() {
            if let calendar = eventStore.calendar(withIdentifier: ownership.calendarIdentifier) {
                guard calendar.allowsContentModifications else { throw CalendarError.calendarUnavailable }
                return ownership
            }
            // A completed cleanup leaves no managed events to lose track of.
            // An unresolved connection that still owes cleanup must retain its identity.
            guard !ownership.needsCleanup else { throw CalendarError.calendarUnavailable }
        }
        guard let source = eventStore.defaultCalendarForNewEvents?.source
                ?? eventStore.sources.first(where: { $0.sourceType == .local }) else {
            throw CalendarError.calendarUnavailable
        }
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Bin Day NZ"
        calendar.source = source
        calendar.cgColor = CGColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1)
        do { try eventStore.saveCalendar(calendar, commit: true) }
        catch { throw CalendarError.calendarUnavailable }
        let ownership = Ownership(calendarIdentifier: calendar.calendarIdentifier,
                                  token: UUID().uuidString, itemIdentifiers: [], needsCleanup: false,
                                  searchStart: Date(), searchEnd: Date())
        try saveOwnership(ownership)
        return ownership
    }

    private func loadOwnership() throws -> Ownership? {
        guard let data = defaults.data(forKey: Self.ownershipKey) else { return nil }
        do { return try JSONDecoder().decode(Ownership.self, from: data) }
        catch { throw CalendarError.ownershipUnavailable }
    }

    private func saveOwnership(_ ownership: Ownership) throws {
        defaults.set(try JSONEncoder().encode(ownership), forKey: Self.ownershipKey)
    }

    private func ownedEvents(_ ownership: Ownership) throws -> [EKEvent] {
        guard let calendar = eventStore.calendar(withIdentifier: ownership.calendarIdentifier),
              calendar.allowsContentModifications else { throw CalendarError.calendarUnavailable }
        var candidates = ownership.itemIdentifiers.compactMap {
            eventStore.calendarItem(withIdentifier: $0) as? EKEvent
        }
        let dateCalendar = ScheduleEngine.collectionCalendar
        var start = min(ownership.searchStart, Date())
        let end = max(ownership.searchEnd, dateCalendar.date(byAdding: .day, value: 28, to: Date())!)
        // EventKit IDs can change after account sync. Recover only within our saved calendar and token.
        // Date predicates have a four-year cap, so query shorter consecutive windows.
        while start < end {
            let next = min(end, dateCalendar.date(byAdding: .year, value: 3, to: start)!)
            candidates += eventStore.events(matching: eventStore.predicateForEvents(
                withStart: start, end: next, calendars: [calendar]
            ))
            start = next
        }
        var result: [String: EKEvent] = [:]
        for candidate in candidates {
            guard Self.ownsEvent(calendarIdentifier: candidate.calendar?.calendarIdentifier,
                                 marker: candidate.url, ownedCalendarIdentifier: ownership.calendarIdentifier,
                                 token: ownership.token) else { continue }
            let event = eventStore.calendarItem(withIdentifier: candidate.calendarItemIdentifier) as? EKEvent ?? candidate
            guard Self.ownsEvent(calendarIdentifier: event.calendar?.calendarIdentifier,
                                 marker: event.url, ownedCalendarIdentifier: ownership.calendarIdentifier,
                                 token: ownership.token) else { continue }
            result[event.calendarItemIdentifier] = event
        }
        return Array(result.values)
    }

    static func ownershipMarker(token: String, eventKey: String) -> URL {
        var components = URLComponents()
        components.scheme = "bindaynz"
        components.host = "calendar"
        components.path = "/\(token)"
        components.queryItems = [URLQueryItem(name: "event", value: eventKey)]
        return components.url!
    }

    static func ownsEvent(calendarIdentifier: String?, marker: URL?, ownedCalendarIdentifier: String, token: String) -> Bool {
        guard !ownedCalendarIdentifier.isEmpty, !token.isEmpty,
              calendarIdentifier == ownedCalendarIdentifier,
              let marker, marker.scheme == "bindaynz", marker.host == "calendar",
              marker.path == "/\(token)",
              let key = URLComponents(url: marker, resolvingAgainstBaseURL: false)?.queryItems?
                .first(where: { $0.name == "event" })?.value else { return false }
        return !key.isEmpty
    }

    static func plannedEvents(zone: CollectionZone, reminderOffsets: [TimeInterval] = []) throws -> [PlannedEvent] {
        let calendar = ScheduleEngine.collectionCalendar
        guard zone.isValid,
              Set(zone.schedules.map(\.id)).count == zone.schedules.count,
              reminderOffsets.allSatisfy({ $0.isFinite && $0 >= -86400 && $0 < 86400 && $0.truncatingRemainder(dividingBy: 60) == 0 }) else {
            throw CalendarError.invalidSchedule
        }
        var plans: [PlannedEvent] = []
        for schedule in zone.schedules {
            var start = calendar.startOfDay(for: schedule.anchorDate)
            let interval = schedule.frequency.intervalDays
            func append(start: Date, before excludedDate: Date?, repeating: Bool) throws {
                let offsets: [TimeInterval?] = [nil] + Array(Set(reminderOffsets)).sorted().map { Optional($0) }
                for offset in offsets {
                    let eventStart = try offset.map { try reminderDate(collectionDate: start, offset: $0) } ?? start
                    let recurrenceEnd = try excludedDate.map { date in
                        let last = try offset.map { try reminderDate(collectionDate: date, offset: $0) } ?? date
                        return last.addingTimeInterval(-1)
                    }
                    let suffix = offset.map { String($0) } ?? "collection"
                    plans.append(PlannedEvent(
                        key: "\(schedule.id)|\(Int(start.timeIntervalSince1970))|\(suffix)",
                        binType: schedule.binType, start: eventStart,
                        end: offset == nil ? calendar.date(byAdding: .day, value: 1, to: start)! : eventStart.addingTimeInterval(60),
                        intervalWeeks: repeating ? interval / 7 : nil,
                        recurrenceEnd: recurrenceEnd, isReminder: offset != nil
                    ))
                }
            }
            for change in schedule.changes.sorted(by: { $0.originalDate < $1.originalDate }) {
                let original = calendar.startOfDay(for: change.originalDate)
                if start < original { try append(start: start, before: original, repeating: true) }
                if let replacement = change.replacementDate {
                    try append(start: calendar.startOfDay(for: replacement), before: nil, repeating: false)
                }
                start = calendar.date(byAdding: .day, value: interval, to: original)!
            }
            try append(start: start, before: nil, repeating: true)
        }
        return plans
    }

    static func reminderDate(collectionDate: Date, offset: TimeInterval) throws -> Date {
        guard offset.isFinite, offset >= -86400, offset < 86400,
              offset.truncatingRemainder(dividingBy: 60) == 0 else { throw CalendarError.invalidSchedule }
        let calendar = ScheduleEngine.collectionCalendar
        let dayOffset = Int(floor(offset / 86400))
        let seconds = Int(offset - Double(dayOffset * 86400))
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: collectionDate),
              let date = calendar.date(bySettingHour: seconds / 3600, minute: (seconds % 3600) / 60, second: 0, of: day) else {
            throw CalendarError.invalidSchedule
        }
        return date
    }

    /// A 90-day snapshot including one-off changes; importing it does not create a subscription.
    func generateICSFile(zone: CollectionZone) -> URL? {
        guard zone.isValid else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BinDayNZ.ics")
        do {
            try Self.icsContent(zone: zone).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch { return nil }
    }

    static func icsContent(zone: CollectionZone, from date: Date = Date()) -> String {
        let calendar = ScheduleEngine.collectionCalendar
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyyMMdd"
        let stamp = DateFormatter()
        stamp.calendar = Calendar(identifier: .gregorian)
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.timeZone = TimeZone(secondsFromGMT: 0)
        stamp.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Bin Day NZ//EN", "CALSCALE:GREGORIAN", "X-WR-CALNAME:Bin Day NZ"]
        let start = calendar.startOfDay(for: date)
        let engine = ScheduleEngine()
        for offset in 0..<90 {
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            for bin in engine.binsCollectedOn(date: day, zone: zone) {
                let dateString = formatter.string(from: day)
                lines += [
                    "BEGIN:VEVENT",
                    "UID:\(escapeICSText("\(zone.id)-\(bin.rawValue)-\(dateString)@bindaynz"))",
                    "DTSTAMP:\(stamp.string(from: date))",
                    "DTSTART;VALUE=DATE:\(dateString)",
                    "DTEND;VALUE=DATE:\(formatter.string(from: calendar.date(byAdding: .day, value: 1, to: day)!))",
                    "SUMMARY:\(escapeICSText("\(bin.icon) \(bin.displayName)"))",
                    "DESCRIPTION:\(escapeICSText(bin.acceptedItems.joined(separator: "\n")))",
                    "TRANSP:TRANSPARENT", "END:VEVENT"
                ]
            }
        }
        lines.append("END:VCALENDAR")
        return lines.map(foldICSLine).joined(separator: "\r\n") + "\r\n"
    }

    static func escapeICSText(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\", options: .literal)
            .replacingOccurrences(of: "\r\n", with: "\n", options: .literal)
            .replacingOccurrences(of: "\r", with: "\n", options: .literal)
            .replacingOccurrences(of: "\n", with: "\\n", options: .literal)
            .replacingOccurrences(of: ";", with: "\\;", options: .literal)
            .replacingOccurrences(of: ",", with: "\\,", options: .literal)
    }

    static func foldICSLine(_ line: String) -> String {
        var result = ""
        var byteCount = 0
        for scalar in line.unicodeScalars {
            let value = String(scalar)
            if byteCount + value.utf8.count > 75 {
                result += "\r\n "
                byteCount = 1
            }
            result += value
            byteCount += value.utf8.count
        }
        return result
    }
}

enum CalendarError: LocalizedError {
    case accessDenied, calendarUnavailable, ownershipUnavailable, invalidSchedule, updateFailed, updateInProgress

    var errorDescription: String? {
        switch self {
        case .accessDenied: return L("Calendar access was denied. Please enable it in Settings.")
        case .calendarUnavailable: return L("A writable Bin Day NZ calendar could not be created or opened. Check your Calendar accounts and try again.")
        case .ownershipUnavailable: return L("Saved calendar ownership could not be read. No calendar events were changed.")
        case .invalidSchedule: return L("The collection schedule or reminder time is invalid. Check your schedule and try again.")
        case .updateFailed: return L("Calendar events could not be updated. Please try again.")
        case .updateInProgress: return L("A calendar update is already in progress. Please try again shortly.")
        }
    }
}
