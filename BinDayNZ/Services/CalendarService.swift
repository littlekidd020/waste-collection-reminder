import Foundation
import EventKit

/// Service for integrating with Apple Calendar (EventKit) and generating .ics files.
final class CalendarService {

    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    private let engine = ScheduleEngine()

    private init() {}

    // MARK: - Permission

    /// Request calendar access permission.
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await eventStore.requestFullAccessToEvents()
            } else {
                return try await eventStore.requestAccess(to: .event)
            }
        } catch {
            print("⚠️ Calendar access error: \(error)")
            return false
        }
    }

    // MARK: - Apple Calendar Sync

    /// Sync collection events to Apple Calendar.
    /// Creates a dedicated "Bin Day NZ" calendar and adds events for upcoming collections.
    func syncToAppleCalendar(zone: CollectionZone) async throws {
        let hasAccess = await requestAccess()
        guard hasAccess else {
            throw CalendarError.accessDenied
        }

        // Find or create "Bin Day NZ" calendar
        let binCalendar = findOrCreateBinCalendar()

        // Remove existing events from our calendar (refresh)
        removeExistingEvents(from: binCalendar)

        // Add upcoming collections (next 3 months)
        let upcoming = engine.upcomingCollections(for: zone, from: Date(), count: 90)

        for collection in upcoming {
            let event = EKEvent(eventStore: eventStore)
            event.title = "\(collection.binType.icon) \(collection.binType.displayName)"
            event.startDate = collection.date
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: collection.date)
            event.isAllDay = true
            event.calendar = binCalendar
            event.notes = notesForBinType(collection.binType)

            try eventStore.save(event, span: .thisEvent)
        }
    }

    // MARK: - .ics File Generation

    /// Generate an .ics file for calendar subscription.
    /// Returns the URL of the generated file.
    func generateICSFile(zone: CollectionZone) -> URL? {
        let upcoming = engine.upcomingCollections(for: zone, from: Date(), count: 90)

        var icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Bin Day NZ//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:Bin Day NZ
        X-WR-TIMEZONE:Pacific/Auckland

        """

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        for collection in upcoming {
            let dateString = dateFormatter.string(from: collection.date)
            let uid = "\(collection.binType.rawValue)-\(dateString)@bindaynz"

            icsContent += """
            BEGIN:VEVENT
            DTSTART;VALUE=DATE:\(dateString)
            SUMMARY:\(collection.binType.icon) \(collection.binType.displayName)
            DESCRIPTION:\(collection.binType.acceptedItems.joined(separator: "\\n"))
            UID:\(uid)
            STATUS:CONFIRMED
            END:VEVENT

            """
        }

        icsContent += "END:VCALENDAR"

        // Write to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("BinDayNZ.ics")

        do {
            try icsContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("⚠️ Failed to write .ics file: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private func findOrCreateBinCalendar() -> EKCalendar {
        // Check if "Bin Day NZ" calendar already exists
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == "Bin Day NZ" }) {
            return existing
        }

        // Create new calendar
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Bin Day NZ"
        calendar.cgColor = CGColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1.0) // Green

        // Use the default calendar source
        if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = defaultSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
        } catch {
            print("⚠️ Failed to create calendar: \(error)")
            // Fall back to default calendar
            return eventStore.defaultCalendarForNewEvents ?? calendar
        }

        return calendar
    }

    private func removeExistingEvents(from calendar: EKCalendar) {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: startDate) ?? startDate
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )
        let events = eventStore.events(matching: predicate)
        for event in events {
            try? eventStore.remove(event, span: .thisEvent)
        }
    }

    private func notesForBinType(_ binType: BinType) -> String {
        let accepted = binType.acceptedItems.prefix(5).joined(separator: "\n• ")
        return "Put in this bin:\n• \(accepted)"
    }
}

// MARK: - Errors

enum CalendarError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return String(localized: "Calendar access was denied. Please enable it in Settings.")
        }
    }
}
