import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    @State private var storageError = false
    @State private var sharedZone: CollectionZone?
    @State private var sharedCouncil: Council?

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
                        let profile = UserProfile()
                        #if DEBUG
                        if DebugSeed.isRequested { DebugSeed.apply(to: profile) }
                        #endif
                        modelContext.insert(profile)
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
            if let zone = ScheduleLink.zone(from: url) {
                sharedCouncil = ScheduleLink.council(from: url)
                sharedZone = zone
            }
        }
        .sheet(item: $sharedZone) { zone in
            let council = sharedCouncil ?? profiles.first.flatMap { DataService.shared.council(for: $0) }
            ManualScheduleView(initialZone: zone, council: council, intro: L("Review this shared schedule, then confirm it matches your property.")) { confirmed in
                guard let profile = profiles.first else { return }
                Task { @MainActor in
                    try? await ScheduleCoordinator.shared.save(zone: confirmed, council: council, address: profile.address, coordinate: nil, profile: profile, context: modelContext)
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

/// Three tabs, Today, Schedule and Guide, in Liquid Glass. Settings is a sheet behind the gear on Today.
struct MainTabView: View {
    @State private var selectedTab: MainTab = .today
    @State private var showSettings = false
    @AppStorage("pendingSetupComplete") private var pendingSetupComplete = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(L("Today"), systemImage: "sun.horizon", value: MainTab.today) {
                TodayView(openSettings: { showSettings = true })
            }
            Tab(L("Schedule"), systemImage: "calendar", value: MainTab.schedule) {
                ScheduleView()
            }
            Tab(L("Guide"), systemImage: "book", value: MainTab.guide) {
                GuideView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Palette.accent)
        .onReceive(NotificationCenter.default.publisher(for: .binDayOpenTab)) { note in
            // Reminders carry the old tab indexes: 0 Today, 1 Schedule, 2 Guide, 3 Settings.
            switch note.object as? Int {
            case 1: selectedTab = .schedule
            case 2: selectedTab = .guide
            case 3: selectedTab = .today; showSettings = true
            default: selectedTab = .today
            }
        }
        .sheet(isPresented: $pendingSetupComplete) { SetupCompleteView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }
}

enum MainTab: Hashable {
    case today, schedule, guide
}
