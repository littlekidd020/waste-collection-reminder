import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    var body: some View {
        NavigationStack {
            if let profile = profiles.first {
                SettingsFormView(profile: profile)
                    .navigationTitle(L("Settings"))
            }
        }
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct SettingsFormView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var showAddressSearch = false
    @State private var confirmRemoval = false
    @State private var confirmLocalOnly = false
    @State private var isRemoving = false
    @State private var alertMessage: String?
    @State private var shareItem: ShareItem?
    private let coordinator = ScheduleCoordinator.shared
    private var zone: CollectionZone? { DataService.shared.zone(for: profile) }
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        return "\(info["CFBundleShortVersionString"] as? String ?? "—") (\(info["CFBundleVersion"] as? String ?? "—"))"
    }

    var body: some View {
        Form {
            Section(L("Your schedule")) {
                if let address = profile.address { Text(address) }
                Label(L("User-confirmed schedule"), systemImage: "checkmark.circle")
                if let date = profile.scheduleConfirmedAt {
                    Text(L("Confirmed %@", collectionDateLabel(date, template: "d MMMM yyyy"))).font(.footnote)
                }
                Button(L("Change schedule")) { showAddressSearch = true }
                if let zone, let text = ScheduleLink.shareText(for: zone) {
                    ShareLink(item: text) { Label(L("Share with your household"), systemImage: "square.and.arrow.up") }
                }
                Link(L("Check official collection dates"), destination: DataService.collectionURL)
                Link(L("Report a missed collection"), destination: DataService.missedCollectionURL)
                Link(L("Book an inorganic collection"), destination: DataService.inorganicBookingURL)
            }
            ReminderPreferenceFields(profile: profile)
            PauseRemindersSection(profile: profile)
            Section {
                if coordinator.isUpdating {
                    ProgressView(L("Updating reminders"))
                } else if !coordinator.hasCheckedAuthorization {
                    Text(L("Checking reminder access…"))
                } else if !coordinator.notificationsAuthorized && profile.reminderPreferences.isEnabled {
                    Text(L("Notifications are not allowed. Enable them in iPhone or iPad Settings."))
                    Button(L("Enable notifications")) {
                        Task {
                            let granted = await NotificationService.shared.requestPermission()
                            if !granted, let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                            await coordinator.refresh(profile: profile, context: modelContext)
                        }
                    }
                } else if let through = profile.remindersScheduledThrough {
                    Text(L("Reminders scheduled through %@", collectionDateLabel(through, template: "d MMMM yyyy")))
                } else if !profile.reminderPreferences.isEnabled {
                    Text(L("App reminders are off."))
                }
                if let message = profile.integrationMessage { Text(message).foregroundStyle(.red) }
                Button(L("Refresh reminders and calendar")) {
                    Task { await coordinator.refresh(profile: profile, context: modelContext) }
                }.disabled(coordinator.isUpdating)
            }.font(.footnote)

            Section {
                Toggle(L("Sync to Calendar"), isOn: $profile.calendarSyncEnabled)
                if profile.calendarSyncEnabled {
                    Toggle(L("Calendar reminder events"), isOn: $profile.calendarRemindersEnabled)
                    Text(L("To avoid duplicate alerts, turn off app notifications if you use calendar alerts."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Button(L("Export 90-day calendar file"), action: exportICS)
                    .disabled(zone == nil)
            } header: { Text(L("Calendar")) }
            .disabled(coordinator.isUpdating)

            Section(L("Language")) {
                Picker(L("Language"), selection: $profile.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }.accessibilityIdentifier("languagePicker")
            }
            Section(L("About")) {
                LabeledContent(L("Version"), value: version)
                NavigationLink(L("How Bin Day works")) { HowItWorksView() }
                NavigationLink(L("Privacy and Help")) { PrivacyView() }
                Link(L("Auckland Council Website"), destination: URL(string: "https://www.aucklandcouncil.govt.nz/rubbish-recycling")!)
                Text(L("Made with ♥ in Aotearoa"))
            }
            Section {
                Button(L("Remove saved data"), role: .destructive) { confirmRemoval = true }
                    .disabled(coordinator.isUpdating)
            }
        }
        .disabled(isRemoving)
        .onChange(of: profile.reminderPreferences) { _, _ in savePreferences() }
        .onChange(of: profile.calendarSyncEnabled) { _, _ in savePreferences() }
        .onChange(of: profile.calendarRemindersEnabled) { _, _ in savePreferences() }
        .sheet(isPresented: $showAddressSearch) { ChangeAddressView() }
        .sheet(item: $shareItem) { ActivityView(activityItems: [$0.url]) }
        .confirmationDialog(L("Remove saved data?"), isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button(L("Remove saved data"), role: .destructive, action: removeData)
                .disabled(coordinator.isUpdating)
        } message: {
            Text(L("This removes your saved address, schedule, app reminders and calendar events created by this version. Other calendar events and exported copies are kept. You will return to setup."))
        }
        .confirmationDialog(L("Calendar events could not be removed"), isPresented: $confirmLocalOnly, titleVisibility: .visible) {
            Button(L("Remove local data only"), role: .destructive) { removeLocalData(forgetCalendarConnection: true) }
                .disabled(coordinator.isUpdating)
        } message: {
            Text(L("This removes your saved data and disconnects calendar sync. Existing calendar events may remain and continue alerting. Remove them in Calendar; Bin Day NZ will no longer track them."))
        }
        .alert(L("Settings Update"), isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button(L("OK"), role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private func savePreferences() {
        do { try modelContext.save() }
        catch {
            modelContext.rollback()
            alertMessage = L("Your settings could not be saved. Please try again.")
            return
        }
        Task { await coordinator.refresh(profile: profile, context: modelContext) }
    }

    private func removeData() {
        guard !coordinator.isUpdating else { alertMessage = L("Updating reminders"); return }
        do { try CalendarService.shared.removeSyncedCalendar() }
        catch { confirmLocalOnly = true; return }
        removeLocalData()
    }

    private func removeLocalData(forgetCalendarConnection: Bool = false) {
        guard !coordinator.isUpdating else { alertMessage = L("Updating reminders"); return }
        isRemoving = true
        defer { isRemoving = false }
        do {
            modelContext.delete(profile)
            try modelContext.save()
            if forgetCalendarConnection { CalendarService.shared.forgetConnection() }
            NotificationService.shared.cancelAllReminders()
            WidgetDataService.clear()
            LanguageManager.shared.apply("en")
        } catch {
            modelContext.rollback()
            alertMessage = L("Saved data could not be removed. Free some device storage and try again. Your schedule has been kept.")
        }
    }

    private func exportICS() {
        guard let zone, let url = CalendarService.shared.generateICSFile(zone: zone) else {
            alertMessage = L("The calendar file could not be created. Please try again.")
            return
        }
        shareItem = ShareItem(url: url)
    }
}

/// Silences reminders for collections up to a chosen day without touching the schedule, so widgets
/// and calendar events keep showing the real dates. The pause clears itself once the day has passed.
struct PauseRemindersSection: View {
    @Bindable var profile: UserProfile
    private var calendar: Calendar { ScheduleEngine.collectionCalendar }
    private var today: Date { calendar.startOfDay(for: Date()) }
    private var defaultEnd: Date { calendar.date(byAdding: .day, value: 7, to: today)! }
    private var latest: Date { calendar.date(byAdding: .year, value: 1, to: today)! }

    private var isPaused: Binding<Bool> {
        Binding(get: { profile.remindersPausedUntil != nil },
                set: { profile.remindersPausedUntil = $0 ? defaultEnd : nil })
    }
    private var pausedUntil: Binding<Date> {
        Binding(get: { profile.remindersPausedUntil ?? defaultEnd },
                set: { profile.remindersPausedUntil = calendar.startOfDay(for: $0) })
    }

    var body: some View {
        Section {
            Toggle(L("Pause reminders while away"), isOn: isPaused)
            if profile.remindersPausedUntil != nil {
                DatePicker(L("Resume after"), selection: pausedUntil, in: today...latest, displayedComponents: .date)
                Text(L("Collections up to that day get no reminders. Your schedule, widget and calendar are unchanged."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
