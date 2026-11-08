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
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Set Up Reminders"))
                        .kerbFont(28, .semibold, relativeTo: .title)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(L("Reminder times stay in New Zealand time, including when you travel."))
                        .kerbFont(17, relativeTo: .body)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)
            }
            .kerbFormRows()
            ReminderPreferenceFields(profile: profile)
            Section {
                Toggle(L("Sync to Calendar"), isOn: $profile.calendarSyncEnabled)
                Text(L("Adds recurring collection events to a separate calendar. Calendar access is optional."))
                    .kerbFootnote()
            } header: { KerbSectionHeader(L("Calendar")) }
            .kerbFormRows()
            Section {
                Text(L("You can finish setup if permission is denied. Today and Settings will explain how to enable reminders later."))
                    .kerbFootnote()
                NavigationLink(L("How Bin Day works")) { HowItWorksView() }
                    .kerbFont(15, relativeTo: .subheadline)
                if let errorMessage { Text(errorMessage).foregroundStyle(Palette.attention) }
            }
            .kerbFormRows()
        }
        .kerbFormGround()
        .disabled(isCompleting)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { OnboardingBackButton(action: onBack).disabled(isCompleting) }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button {
                    Task { await completeSetup() }
                } label: {
                    KerbPrimaryButtonLabel(title: L("Finish Setup"), busy: isCompleting)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(Palette.accent)
                .disabled(isCompleting)
                .accessibilityIdentifier("finishSetup")
                OnboardingPageIndicator(currentPage: 2)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                LinearGradient(colors: [Palette.ground.opacity(0), Palette.ground.opacity(0.94)],
                               startPoint: .top, endPoint: .init(x: 0.5, y: 0.35))
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
        }
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
        Section {
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
                    .kerbFootnote()
            }
        } header: { KerbSectionHeader(L("Notifications")) }
        .kerbFormRows()
    }
}
