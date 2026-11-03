import SwiftUI
import SwiftData
import WidgetKit
import CoreLocation

/// One next collection, one status row, then upcoming dates. Rare actions live in the toolbar menu.
struct TodayView: View {
    @Query private var profiles: [UserProfile]
    @State private var showChangeAddress = false
    @State private var showHowItWorks = false
    @State private var showCouncil = false
    @State private var coordinator = ScheduleCoordinator.shared
    @State private var widgetInstalled: Bool?
    @AppStorage("widgetNudgeDismissed") private var widgetNudgeDismissed = false
    @AppStorage("dismissedHolidayIDs") private var dismissedHolidayIDs = ""
    @Environment(\.modelContext) private var modelContext

    private let engine = ScheduleEngine()
    private var profile: UserProfile? { profiles.first }
    private var currentZone: CollectionZone? {
        profile.flatMap { DataService.shared.zone(for: $0) }
    }

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let profile, let zone = currentZone {
                            let collections = engine.upcomingCollections(for: zone, from: context.date, count: 30)
                            let groups = Dictionary(grouping: collections, by: \.date)
                            let dates = Array(groups.keys.sorted().prefix(6))

                            if let nextDate = dates.first {
                                NextCollectionHero(
                                    date: nextDate,
                                    bins: groups[nextDate, default: []].map(\.binType),
                                    now: context.date
                                )
                            }

                            ForEach(HolidayShiftService.suggestions(for: zone, now: context.date, dismissed: dismissedHolidays)) { suggestion in
                                HolidayShiftCard(suggestion: suggestion) {
                                    applyHoliday(suggestion, zone: zone, profile: profile)
                                } onDismiss: {
                                    dismissHoliday(suggestion.holiday.id)
                                }
                            }

                            ScheduleStatusCard(profile: profile, coordinator: coordinator, now: context.date) {
                                showChangeAddress = true
                            }

                            if shouldNudgeWidget(profile: profile, now: context.date) {
                                WidgetNudgeCard { widgetNudgeDismissed = true }
                            }

                            if dates.count > 1 {
                                VStack(alignment: .leading, spacing: 18) {
                                    Text(L("Upcoming"))
                                        .font(.title3.bold())
                                    ForEach(Array(dates.dropFirst()), id: \.self) { date in
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(collectionDateLabel(date))
                                                .font(.headline)
                                            ForEach(groups[date, default: []]) { collection in
                                                CollectionBinRow(bin: collection.binType)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        if date != dates.last { Divider() }
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView {
                                Label(L("Finish setup"), systemImage: "calendar.badge.exclamationmark")
                            } description: {
                                Text(L("Confirm a collection schedule to see your next bin day."))
                            } actions: {
                                Button(L("Set Collection Schedule")) { showChangeAddress = true }
                                    .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill)
                            }
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle(L("Today"))
            .task { await checkWidgets() }
            .onChange(of: scenePhaseKey) { _, _ in Task { await checkWidgets() } }
            .toolbar {
                if currentZone != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button { showChangeAddress = true } label: {
                                Label(L("Change schedule"), systemImage: "calendar.badge.clock")
                            }
                            Button { showCouncil = true } label: {
                                Label(L("Check dates with Auckland Council"), systemImage: "safari")
                            }
                            Button { showHowItWorks = true } label: {
                                Label(L("How Bin Day works"), systemImage: "questionmark.circle")
                            }
                        } label: {
                            Label(L("Schedule options"), systemImage: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showChangeAddress) { ChangeAddressView() }
            .sheet(isPresented: $showCouncil) { SafariView(url: DataService.collectionURL).ignoresSafeArea() }
            .sheet(isPresented: $showHowItWorks) {
                NavigationStack {
                    HowItWorksView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(L("Done")) { showHowItWorks = false }
                            }
                        }
                }
            }
        }
    }
}

extension TodayView {
    private var scenePhaseKey: Bool { coordinator.isUpdating }

    fileprivate var dismissedHolidays: Set<String> {
        Set(dismissedHolidayIDs.split(separator: ",").map(String.init))
    }

    fileprivate func dismissHoliday(_ id: String) {
        dismissedHolidayIDs = (dismissedHolidays.union([id])).sorted().joined(separator: ",")
    }

    fileprivate func applyHoliday(_ suggestion: HolidaySuggestion, zone: CollectionZone, profile: UserProfile) {
        guard let updated = HolidayShiftService.applying(suggestion, to: zone) else { return }
        let coordinate = profile.latitude.flatMap { lat in profile.longitude.map { CLLocationCoordinate2D(latitude: lat, longitude: $0) } }
        Task { @MainActor in
            try? await ScheduleCoordinator.shared.save(zone: updated, address: profile.address, coordinate: coordinate, profile: profile, context: modelContext)
        }
    }

    /// Two weeks after confirming a schedule, suggest the widget once if none is installed.
    fileprivate func shouldNudgeWidget(profile: UserProfile, now: Date) -> Bool {
        guard widgetInstalled == false, !widgetNudgeDismissed, let confirmed = profile.scheduleConfirmedAt else { return false }
        return now.timeIntervalSince(confirmed) > 14 * 86400
    }

    fileprivate func checkWidgets() async {
        let installed: Bool = await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                continuation.resume(returning: !((try? result.get()) ?? []).isEmpty)
            }
        }
        widgetInstalled = installed
    }
}

private struct NextCollectionHero: View {
    let date: Date
    let bins: [BinType]
    let now: Date

    private var relativeDate: String {
        let calendar = ScheduleEngine.collectionCalendar
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: date).day ?? 0
        if days == 0 { return L("Today") }
        if days == 1 { return L("Tomorrow") }
        return L("Next collection")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(relativeDate)
                .font(.largeTitle.bold())
            Text(collectionDateLabel(date))
                .font(.headline)
                .foregroundStyle(.secondary)
            ForEach(bins) { bin in
                CollectionBinRow(bin: bin)
                    .font(.title3.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

struct CollectionBinRow: View {
    let bin: BinType

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BinLidChip(bin: bin)
            Text(bin.displayName)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Reminder health and schedule provenance in one row. Details and recovery actions expand on demand;
/// an integration warning is always visible.
private struct ScheduleStatusCard: View {
    let profile: UserProfile
    let coordinator: ScheduleCoordinator
    let now: Date
    let onChangeSchedule: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    private enum ReminderState { case checking, off, denied, paused(Date), scheduled(Date), stale }

    private var state: ReminderState {
        if coordinator.isUpdating || !coordinator.hasCheckedAuthorization { return .checking }
        if !profile.reminderPreferences.isEnabled { return .off }
        if !coordinator.notificationsAuthorized { return .denied }
        if let pausedUntil = profile.remindersPausedUntil,
           pausedUntil >= ScheduleEngine.collectionCalendar.startOfDay(for: now) { return .paused(pausedUntil) }
        if let through = profile.remindersScheduledThrough,
           through >= ScheduleEngine.collectionCalendar.startOfDay(for: now) { return .scheduled(through) }
        return .stale
    }

    private var title: String {
        switch state {
        case .checking: return L("Checking reminders")
        case .off: return L("App reminders are off")
        case .denied: return L("Notifications are not allowed")
        case .paused: return L("Reminders paused")
        case .scheduled: return L("Reminders on")
        case .stale: return L("Reminders need refreshing")
        }
    }

    private var symbol: String {
        switch state {
        case .checking, .scheduled: return "bell.badge"
        case .off, .denied, .paused: return "bell.slash"
        case .stale: return "bell.badge.waveform"
        }
    }

    private var subtitle: String? {
        guard let confirmedAt = profile.scheduleConfirmedAt else { return L("Schedule needs confirmation") }
        return L("Confirmed %@", collectionDateLabel(confirmedAt, template: "d MMMM yyyy"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    if case .checking = state {
                        ProgressView().frame(minWidth: 28)
                    } else {
                        Image(systemName: symbol).frame(minWidth: 28).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.headline).foregroundStyle(.primary)
                        if let subtitle {
                            Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel([title, subtitle].compactMap { $0 }.joined(separator: ", "))
            .accessibilityHint(L("Schedule and reminder details"))
            .accessibilityAddTraits(expanded ? [.isSelected] : [])

            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    if let address = profile.address, !address.isEmpty {
                        Label(address, systemImage: "location")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Label(L("User-confirmed schedule"), systemImage: "checkmark.circle")
                    switch state {
                    case .scheduled(let through):
                        Text(L("Reminders scheduled through %@", collectionDateLabel(through, template: "d MMMM")))
                            .foregroundStyle(.secondary)
                    case .denied:
                        Button(L("Open notification settings")) {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                        .frame(minHeight: 44, alignment: .leading)
                    case .off:
                        Text(L("Change reminder preferences in Settings."))
                            .foregroundStyle(.secondary)
                    case .paused(let until):
                        Text(L("Reminders resume for collections after %@. Change this in Settings.", collectionDateLabel(until, template: "d MMMM")))
                            .foregroundStyle(.secondary)
                    case .stale:
                        Text(L("Check reminder settings before relying on the next alert."))
                            .foregroundStyle(.secondary)
                    case .checking:
                        EmptyView()
                    }
                    Button(action: onChangeSchedule) {
                        Label(L("Change schedule"), systemImage: "calendar.badge.clock")
                    }
                    .frame(minHeight: 44, alignment: .leading)
                }
                .font(.subheadline)
                .padding(.leading, 40)
                .transition(reduceMotion ? .identity : .opacity)
            }

            if let message = profile.integrationMessage, !message.isEmpty {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
