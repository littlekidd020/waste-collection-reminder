import SwiftUI
import SwiftData

/// Root view that switches between onboarding and the main tab bar.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        if profile.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

/// Main tab bar with Today, Schedule, Info, and Settings tabs.
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label(String(localized: "Today"), systemImage: "house.fill")
                }

            ScheduleView()
                .tabItem {
                    Label(String(localized: "Schedule"), systemImage: "calendar")
                }

            InfoView()
                .tabItem {
                    Label(String(localized: "Info"), systemImage: "info.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "Settings"), systemImage: "gearshape.fill")
                }
        }
        .tint(.green)
    }
}
