import SwiftUI
import SwiftData

/// Container view that manages the onboarding flow as a paged experience.
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var currentPage = 0
    @State private var selectedCouncil: Council?
    @State private var selectedZone: CollectionZone?
    @State private var selectedAddress: String?

    private let dataService = DataService.shared

    private var profile: UserProfile {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView(onContinue: { currentPage = 1 })
                .tag(0)

            CouncilPickerView(
                selectedCouncil: $selectedCouncil,
                onContinue: { currentPage = 2 }
            )
            .tag(1)

            AddressSearchView(
                council: selectedCouncil,
                selectedZone: $selectedZone,
                selectedAddress: $selectedAddress,
                onContinue: { currentPage = 3 },
                onManualSetup: { currentPage = 3 }
            )
            .tag(2)

            NotificationSetupView(onComplete: {
                completeOnboarding()
            })
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
        .ignoresSafeArea()
    }

    private func completeOnboarding() {
        profile.councilId = selectedCouncil?.id
        profile.zoneId = selectedZone?.id
        profile.address = selectedAddress
        profile.hasCompletedOnboarding = true
        try? modelContext.save()
    }
}
