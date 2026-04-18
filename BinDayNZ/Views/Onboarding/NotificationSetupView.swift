import SwiftUI
import SwiftData

/// Notification & Calendar setup — final page of onboarding.
struct NotificationSetupView: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var notifyEvening = true
    @State private var notifyMorning = true
    @State private var eveningTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    @State private var morningTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var calendarSync = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                        .padding(.bottom, 8)

                    Text(L("Set Up Reminders"))
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text(L("Choose when you'd like to be reminded"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                // Settings cards
                VStack(spacing: 16) {
                    // Evening reminder
                    ReminderCardView(
                        icon: "moon.fill",
                        title: L("Evening Before"),
                        subtitle: L("Get reminded to put your bin out tonight"),
                        isEnabled: $notifyEvening,
                        time: $eveningTime
                    )

                    // Morning reminder
                    ReminderCardView(
                        icon: "sun.max.fill",
                        title: L("Morning Of"),
                        subtitle: L("Quick reminder on collection morning"),
                        isEnabled: $notifyMorning,
                        time: $morningTime
                    )

                    // Calendar sync
                    CalendarSyncRow(calendarSync: $calendarSync)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Complete button
                Button(action: {
                    savePreferences()
                    onComplete()
                }) {
                    Text(L("All Set! 🎉"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.green)
                        )
                }
                .padding(.horizontal, 32)

                // Page indicator
                HStack(spacing: 8) {
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.secondary).frame(width: 8, height: 8)
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func savePreferences() {
        guard let profile = profile else { return }
        profile.notifyEveningBefore = notifyEvening
        profile.eveningNotifyTime = eveningTime
        profile.notifyMorningOf = notifyMorning
        profile.morningNotifyTime = morningTime
        profile.calendarSyncEnabled = calendarSync
        try? modelContext.save()
    }
}

// MARK: - Subviews

private struct ReminderCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .tint(.green)
            }

            if isEnabled {
                HStack {
                    Spacer()
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct CalendarSyncRow: View {
    @Binding var calendarSync: Bool

    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(L("Add to Calendar"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(L("Sync collection dates with your calendar app"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $calendarSync)
                .tint(.green)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}
