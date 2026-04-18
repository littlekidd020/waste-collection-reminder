import SwiftUI
import SwiftData

/// Root view that switches between onboarding and the main tab bar.
/// Language changes take effect immediately via LanguageManager + view rebuild.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var languageRefreshID = UUID()

    private var profile: UserProfile {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        Group {
            if profile.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .id(languageRefreshID)
        .environment(\.locale, LanguageManager.shared.locale)
        .onAppear {
            LanguageManager.shared.apply(profile.languageCode)
        }
        .onChange(of: profile.languageCode) { _, newCode in
            LanguageManager.shared.apply(newCode)
            // Force full view tree rebuild so all L() calls re-execute
            withAnimation(.easeInOut(duration: 0.15)) {
                languageRefreshID = UUID()
            }
        }
    }
}

/// Main tab bar with Today, Schedule, Info, and Settings tabs.
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label(L("Today"), systemImage: "house.fill")
                }

            ScheduleView()
                .tabItem {
                    Label(L("Schedule"), systemImage: "calendar")
                }

            InfoView()
                .tabItem {
                    Label(L("Info"), systemImage: "info.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label(L("Settings"), systemImage: "gearshape.fill")
                }
        }
        .tint(.green)
    }
}
