import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    SettingsFormView(profile: profile)
                } else {
                    LinenGround()
                }
            }
            .navigationTitle(L("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) { dismiss() }
                }
            }
        }
        .tint(Palette.accent)
    }
}

// MARK: - Kerb styling for system forms and lists

/// Forms and lists keep their system structure but stand on the linen: no grouped fills, rows on
/// the ground separated by hairlines, palette text, the moss accent for controls.
extension View {
    func kerbFormGround() -> some View {
        self.scrollContentBackground(.hidden)
            .background { LinenGround() }
            .tint(Palette.accent)
            .foregroundStyle(Palette.ink)
    }

    /// Applied to a `Section` (or row): the row sits on the ground and its separator is a hairline.
    func kerbFormRows() -> some View {
        self.listRowBackground(Palette.surface.opacity(0))
            .listRowSeparatorTint(Palette.line)
    }

    /// Secondary explanatory text under a control.
    func kerbFootnote() -> some View {
        self.kerbFont(13, relativeTo: .footnote)
            .foregroundStyle(Palette.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A form section header as a small tracked label.
struct KerbSectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title).kerbLabel(12)
    }
}

/// The one primary action of a step: a moss Liquid Glass capsule that spans the content width.
/// On `.glassProminent` the text is `Palette.onAccent` (the system white fails on the light dark-mode
/// moss); pass `prominent: false` for a secondary `.glass` capsule, which takes ink.
struct KerbPrimaryButtonLabel: View {
    let title: String
    var systemImage: String? = nil
    var busy = false
    var prominent = true
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
            if busy { ProgressView().tint(isEnabled ? Palette.onAccent : Palette.muted) }
        }
        .kerbFont(17, .semibold, relativeTo: .headline)
        .foregroundStyle(!isEnabled ? Palette.muted : prominent ? Palette.onAccent : Palette.ink)
        .frame(maxWidth: .infinity, minHeight: 36)
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
    private var council: Council? { DataService.shared.council(for: profile) }
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        return "\(info["CFBundleShortVersionString"] as? String ?? "—") (\(info["CFBundleVersion"] as? String ?? "—"))"
    }

    var body: some View {
        Form {
            Section {
                if let address = profile.address { Text(address) }
                if let council {
                    LabeledContent(L("Council")) {
                        Text(council.name).foregroundStyle(Palette.muted)
                    }
                }
                Label {
                    Text(L("User-confirmed schedule"))
                } icon: {
                    Image(systemName: "checkmark.circle").foregroundStyle(Palette.accent)
                }
                if let date = profile.scheduleConfirmedAt {
                    Text(L("Confirmed %@", collectionDateLabel(date, template: "d MMMM yyyy"))).kerbFootnote()
                }
                Button(L("Change schedule")) { showAddressSearch = true }
                    .foregroundStyle(.tint)
                if let zone, let text = ScheduleLink.shareText(for: zone, council: council) {
                    ShareLink(item: text) { Label(L("Share with your household"), systemImage: "square.and.arrow.up") }
                        .foregroundStyle(.tint)
                }
            } header: { KerbSectionHeader(L("Your schedule")) }
            .kerbFormRows()

            ReminderPreferenceFields(profile: profile)
            PauseRemindersSection(profile: profile)
            Section {
                Group {
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
                        .foregroundStyle(.tint)
                    } else if let through = profile.remindersScheduledThrough {
                        Text(L("Reminders scheduled through %@", collectionDateLabel(through, template: "d MMMM yyyy")))
                    } else if !profile.reminderPreferences.isEnabled {
                        Text(L("App reminders are off."))
                    }
                    if let message = profile.integrationMessage { Text(message).foregroundStyle(Palette.attention) }
                    Button(L("Refresh reminders and calendar")) {
                        Task { await coordinator.refresh(profile: profile, context: modelContext) }
                    }
                    .foregroundStyle(.tint)
                    .disabled(coordinator.isUpdating)
                }
                .kerbFont(15, relativeTo: .subheadline)
            }
            .kerbFormRows()

            Section {
                Toggle(L("Sync to Calendar"), isOn: $profile.calendarSyncEnabled)
                if profile.calendarSyncEnabled {
                    Toggle(L("Calendar reminder events"), isOn: $profile.calendarRemindersEnabled)
                    Text(L("To avoid duplicate alerts, turn off app notifications if you use calendar alerts."))
                        .kerbFootnote()
                }
                Button(L("Export 90-day calendar file"), action: exportICS)
                    .foregroundStyle(.tint)
                    .disabled(zone == nil)
            } header: { KerbSectionHeader(L("Calendar")) }
            .kerbFormRows()
            .disabled(coordinator.isUpdating)

            Section {
                Picker(L("Language"), selection: $profile.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }.accessibilityIdentifier("languagePicker")
            } header: { KerbSectionHeader(L("Language")) }
            .kerbFormRows()

            // What the old Info tab linked to, each link once.
            Section {
                if let council {
                    Link(destination: council.website) { resource(L("Council website"), "globe") }
                    Link(destination: council.collectionDayURL) { resource(L("Check dates with %@", council.name), "safari") }
                    if council == CouncilDirectory.auckland {
                        Link(destination: DataService.aucklandMissedCollectionURL) { resource(L("Report a missed collection"), "exclamationmark.bubble") }
                        Link(destination: DataService.aucklandInorganicBookingURL) { resource(L("Book an inorganic collection"), "shippingbox") }
                        Link(destination: DataService.aucklandItemFinderURL) { resource(L("Find where an item goes"), "magnifyingglass") }
                    }
                }
                NavigationLink { HowItWorksView(council: council) } label: { resource(L("How Bin Day works"), "questionmark.circle") }
                NavigationLink { PrivacyView(council: council) } label: { resource(L("Privacy and Help"), "hand.raised") }
            } header: { KerbSectionHeader(L("Resources")) }
            .kerbFormRows()

            Section {
                LabeledContent(L("Version")) {
                    Text(version).foregroundStyle(Palette.muted).monospacedDigit()
                }
                Text(L("Made with ♥ in Aotearoa")).foregroundStyle(Palette.muted)
            } header: { KerbSectionHeader(L("About")) }
            .kerbFormRows()

            Section {
                Button(role: .destructive) { confirmRemoval = true } label: {
                    Text(L("Remove saved data")).foregroundStyle(Palette.attention)
                }
                .disabled(coordinator.isUpdating)
            }
            .kerbFormRows()
        }
        .kerbFormGround()
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

    /// A resource row: ink title, muted symbol, a full 44 pt target.
    private func resource(_ title: String, _ symbol: String) -> some View {
        Label {
            Text(title).foregroundStyle(Palette.ink)
        } icon: {
            Image(systemName: symbol).foregroundStyle(Palette.muted)
        }
        .frame(minHeight: 44, alignment: .leading)
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
                    .kerbFootnote()
            }
        }
        .kerbFormRows()
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
