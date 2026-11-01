import SwiftUI
import SwiftData
import CoreLocation

struct NotificationSetupView: View {
    @Bindable var profile: UserProfile
    let zone: CollectionZone
    let address: String
    let coordinate: CLLocationCoordinate2D?
    let onBack: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var isCompleting = false
    @State private var errorMessage: String?

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
                Text(L("App reminders have a limited window. Open Bin Day NZ regularly to renew them; the app also schedules a renewal reminder. Settings shows the last scheduled collection date."))
                    .font(.footnote)
                Text(L("You can finish setup if permission is denied. Today and Settings will explain how to enable reminders later."))
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
            try await ScheduleCoordinator.shared.save(zone: zone, address: address, coordinate: coordinate, profile: profile, context: modelContext)
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
        }
    }
}
