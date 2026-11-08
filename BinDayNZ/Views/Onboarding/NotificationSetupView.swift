import SwiftUI
import SwiftData
import CoreLocation

struct NotificationSetupView: View {
    @Bindable var profile: UserProfile
    let zone: CollectionZone
    let council: Council?
    let address: String
    let coordinate: CLLocationCoordinate2D?
    let onBack: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var isCompleting = false
    @State private var errorMessage: String?
    @AppStorage("pendingSetupComplete") private var pendingSetupComplete = false

    var body: some View {
        Form {
            Section {
                OnboardingBackButton(action: onBack)
                Text(L("Set Up Reminders")).font(.title.bold())
                Text(L("Reminder times stay in New Zealand time, including when you travel."))
            }
            ReminderPreferenceFields(profile: profile)
            Section {
                Toggle(L("Sync to Calendar"), isOn: $profile.calendarSyncEnabled)
                Text(L("Adds recurring collection events to a separate calendar. Calendar access is optional."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Text(L("You can finish setup if permission is denied. Today and Settings will explain how to enable reminders later."))
                    .font(.footnote)
                NavigationLink(L("How Bin Day works")) { HowItWorksView() }
                    .font(.footnote)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                Button {
                    Task { await completeSetup() }
                } label: {
                    HStack {
                        Text(L("Finish Setup")).font(.headline)
                        if isCompleting { ProgressView() }
                    }.frame(maxWidth: .infinity, minHeight: 44)
                }.accessibilityIdentifier("finishSetup")
            }
            OnboardingPageIndicator(currentPage: 2)
                .frame(maxWidth: .infinity).listRowBackground(Color.clear)
        }
        .disabled(isCompleting)
    }

    @MainActor private func completeSetup() async {
        isCompleting = true
        errorMessage = nil
        defer { isCompleting = false }
        if profile.reminderPreferences.isEnabled {
            _ = await NotificationService.shared.requestPermission()
        }
        do {
            try await ScheduleCoordinator.shared.save(zone: zone, council: council, address: address, coordinate: coordinate, profile: profile, context: modelContext)
            pendingSetupComplete = true
        } catch {
            errorMessage = L("Your schedule could not be saved. Please try again.")
        }
    }
}

struct ReminderPreferenceFields: View {
    @Bindable var profile: UserProfile
    var body: some View {
        Section(L("Notifications")) {
            Toggle(L("Evening Before"), isOn: $profile.notifyEveningBefore)
            if profile.notifyEveningBefore || profile.calendarRemindersEnabled {
                DatePicker(L("Evening reminder time"), selection: $profile.eveningNotifyTime, displayedComponents: .hourAndMinute)
            }
            Toggle(L("Morning Of"), isOn: $profile.notifyMorningOf)
            if profile.notifyMorningOf || profile.calendarRemindersEnabled {
                DatePicker(L("Morning reminder time"), selection: $profile.morningNotifyTime, displayedComponents: .hourAndMinute)
            }
            Toggle(L("Bring bins in"), isOn: $profile.notifyBringIn)
            if profile.notifyBringIn {
                DatePicker(L("Bring-in reminder time"), selection: $profile.bringInNotifyTime, displayedComponents: .hourAndMinute)
                Text(L("A third reminder on collection day. Each extra reminder shortens how far ahead the batch reaches."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
