import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    @State private var storageError = false
    @State private var sharedZone: CollectionZone?

    var body: some View {
        Group {
            if let profile = profiles.first {
                Group {
                    if profile.hasCompletedOnboarding && DataService.shared.zone(for: profile) != nil {
                        MainTabView()
                    } else {
                        OnboardingContainerView(profile: profile)
                    }
                }
                .task { await refresh(profile) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await refresh(profile) } }
                }
                .onChange(of: profile.languageCode) { _, code in
                    LanguageManager.shared.apply(code)
                    do { try modelContext.save() }
                    catch { modelContext.rollback(); storageError = true }
                    Task { await refresh(profile) }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    Task { await refresh(profile) }
                }
            } else {
                ProgressView(L("Loading…"))
                    .task {
                        guard profiles.isEmpty else { return }
                        modelContext.insert(UserProfile())
                        do { try modelContext.save() }
                        catch { modelContext.rollback(); storageError = true }
                    }
            }
        }
        .environment(\.locale, LanguageManager.shared.locale)
        .environment(\.calendar, ScheduleEngine.collectionCalendar)
        .environment(\.timeZone, ScheduleEngine.collectionCalendar.timeZone)
        .tint(AppTheme.accent)
        .onOpenURL { url in
            if let zone = ScheduleLink.zone(from: url) { sharedZone = zone }
        }
        .sheet(item: $sharedZone) { zone in
            ManualScheduleView(initialZone: zone, intro: L("Review this shared schedule, then confirm it matches your property.")) { confirmed in
                guard let profile = profiles.first else { return }
                Task { @MainActor in
                    try? await ScheduleCoordinator.shared.save(zone: confirmed, address: profile.address, coordinate: nil, profile: profile, context: modelContext)
                }
            }
        }
        .alert(L("Storage needs attention"), isPresented: $storageError) {
            Button(L("OK"), role: .cancel) {}
        } message: {
            Text(L("Your saved information could not be updated. Free some device storage and reopen Bin Day NZ. Existing data has not been reset."))
        }
    }

    @MainActor private func refresh(_ profile: UserProfile) async {
        guard profile.modelContext === modelContext, !profile.isDeleted else { return }
        LanguageManager.shared.apply(profile.languageCode)
        await ScheduleCoordinator.shared.refresh(profile: profile, context: modelContext)
    }
}

/// Main tab bar with Today, Schedule, Info, and Settings tabs.
struct MainTabView: View {
    @State private var selectedTab = 0
    @AppStorage("pendingSetupComplete") private var pendingSetupComplete = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tag(0)
                .tabItem {
                    Label(L("Today"), systemImage: selectedTab == 0 ? "house.fill" : "house")
                        .environment(\.symbolVariants, .none)
                }

            ScheduleView()
                .tag(1)
                .tabItem {
                    Label(L("Schedule"), systemImage: "calendar")
                        .environment(\.symbolVariants, .none)
                }

            InfoView()
                .tag(2)
                .tabItem {
                    Label(L("Info"), systemImage: selectedTab == 2 ? "info.circle.fill" : "info.circle")
                        .environment(\.symbolVariants, .none)
                }

            SettingsView()
                .tag(3)
                .tabItem {
                    Label(L("Settings"), systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                        .environment(\.symbolVariants, .none)
                }
        }
        .tint(AppTheme.accent)
        .onReceive(NotificationCenter.default.publisher(for: .binDayOpenTab)) { note in
            if let tab = note.object as? Int { selectedTab = tab }
        }
        .sheet(isPresented: $pendingSetupComplete) { SetupCompleteView() }
    }
}
