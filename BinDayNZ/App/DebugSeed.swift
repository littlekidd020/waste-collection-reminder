import Foundation

#if DEBUG
/// `-BinDaySeedSample [council-id]` on launch seeds a confirmed sample schedule for screenshots and
/// simulator checks: the council's bins on the next Tuesday, rubbish and food weekly, recycling
/// fortnightly, glass and garden waste fortnightly on the other week. Add `-BinDaySeedOtherWeek`
/// to start on the glass-and-garden week instead. Debug builds only.
enum DebugSeed {
    static var isRequested: Bool { CommandLine.arguments.contains("-BinDaySeedSample") }

    static func apply(to profile: UserProfile) {
        let args = CommandLine.arguments
        let requested = args.firstIndex(of: "-BinDaySeedSample").flatMap { index -> Council? in
            guard index + 1 < args.count, !args[index + 1].hasPrefix("-") else { return nil }
            return CouncilDirectory.council(id: args[index + 1])
        }
        let council = requested ?? CouncilDirectory.auckland
        let calendar = ScheduleEngine.collectionCalendar
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let nextTuesday = ManualScheduleView.nextDate(weekday: 2, from: tomorrow)
        let following = calendar.date(byAdding: .day, value: 7, to: nextTuesday)!
        let swap = args.contains("-BinDaySeedOtherWeek")
        let tuesday = swap ? following : nextTuesday
        let otherWeek = swap ? nextTuesday : following
        let schedules = council.services.filter { $0 != .inorganic }.map { bin -> CollectionSchedule in
            switch bin {
            case .recycling: return CollectionSchedule(id: bin.rawValue, binType: bin, frequency: .fortnightly, anchorDate: tuesday)
            case .glass, .gardenWaste: return CollectionSchedule(id: bin.rawValue, binType: bin, frequency: .fortnightly, anchorDate: otherWeek)
            default: return CollectionSchedule(id: bin.rawValue, binType: bin, frequency: .weekly, anchorDate: nextTuesday)
            }
        }
        let zone = DataService.shared.manualZone(schedules: schedules)
        profile.manualSchedulesJSON = try? DataService.shared.encodedManualSchedules(from: zone)
        profile.zoneId = DataService.manualZoneID
        profile.councilId = council.id
        profile.address = council == CouncilDirectory.auckland ? "14 Valley Road, Mount Eden, Auckland 1024" : nil
        profile.scheduleConfirmedAt = Date()
        profile.hasCompletedOnboarding = true
    }
}
#endif
