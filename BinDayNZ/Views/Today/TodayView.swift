import SwiftUI
import SwiftData

/// One next collection, followed by distinct upcoming dates.
struct TodayView: View {
    @Query private var profiles: [UserProfile]
    @State private var showChangeAddress = false
    @State private var coordinator = ScheduleCoordinator.shared

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

                            scheduleSource(profile)
                            ReminderStatusView(profile: profile, coordinator: coordinator, now: context.date)

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
            .sheet(isPresented: $showChangeAddress) { ChangeAddressView() }
        }
    }

    private func scheduleSource(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let address = profile.address, !address.isEmpty {
                Label(address, systemImage: "location")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let confirmedAt = profile.scheduleConfirmedAt {
                Label(L("User-confirmed schedule"), systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.medium))
                Text(L("Confirmed %@", collectionDateLabel(confirmedAt, template: "d MMMM yyyy")))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Label(L("Schedule needs confirmation"), systemImage: "exclamationmark.circle")
                    .font(.subheadline.weight(.medium))
            }
            Button {
                showChangeAddress = true
            } label: {
                Label(L("Change schedule"), systemImage: "calendar.badge.clock")
                    .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill)
            .controlSize(.large)
            Link(L("Check dates with Auckland Council"), destination: DataService.collectionURL)
                .frame(minHeight: 44, alignment: .leading)
        }
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
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: bin.systemImage)
                .symbolVariant(.none)
                .foregroundStyle(bin.color)
                .frame(minWidth: 28)
                .accessibilityHidden(true)
            Text(bin.displayName)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReminderStatusView: View {
    let profile: UserProfile
    let coordinator: ScheduleCoordinator
    let now: Date
    @Environment(\.openURL) private var openURL

    private var remindersRequested: Bool {
        profile.notifyEveningBefore || profile.notifyMorningOf
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if coordinator.isUpdating || !coordinator.hasCheckedAuthorization {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(L("Checking reminders"))
                }
            } else if !remindersRequested {
                Label(L("App reminders are off"), systemImage: "bell.slash")
                Text(L("Change reminder preferences in Settings."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if !coordinator.notificationsAuthorized {
                Label(L("Notifications are not allowed"), systemImage: "bell.slash")
                Button(L("Open notification settings")) {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                }
                .frame(minHeight: 44, alignment: .leading)
            } else if let through = profile.remindersScheduledThrough,
                      through >= ScheduleEngine.collectionCalendar.startOfDay(for: now) {
                Label(L("Reminders scheduled through %@", collectionDateLabel(through, template: "d MMMM")), systemImage: "bell.badge")
                Text(L("Open the app regularly to keep upcoming reminders scheduled. Delivery also depends on your device's notification settings."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Label(L("Reminders need refreshing"), systemImage: "bell.badge")
                Text(L("Check reminder settings before relying on the next alert."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let message = profile.integrationMessage, !message.isEmpty {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
