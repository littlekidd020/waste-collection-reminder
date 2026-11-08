import SwiftUI
import SwiftData
import CoreLocation

struct OnboardingContainerView: View {
    @Bindable var profile: UserProfile
    @State private var currentPage = 0
    @State private var selectedZone: CollectionZone?
    @State private var scheduleReviewed = false
    @State private var selectedAddress: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedCouncil: Council?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if profile.hasCompletedOnboarding {
                    Text(L("Please review your saved collection dates before continuing."))
                        .kerbFont(15, relativeTo: .subheadline)
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24).padding(.top, 12)
                    if let message = profile.integrationMessage {
                        Text(message)
                            .kerbFont(15, relativeTo: .subheadline)
                            .foregroundStyle(Palette.attention)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24).padding(.top, 8)
                    }
                }
                Group {
                switch currentPage {
                case 0:
                    WelcomeView(language: $profile.language, onContinue: { currentPage = 1 })
                case 1:
                    AddressSearchView(selectedZone: $selectedZone, selectedAddress: $selectedAddress, selectedCoordinate: $selectedCoordinate, selectedCouncil: $selectedCouncil, scheduleReviewed: $scheduleReviewed, onBack: { currentPage = 0 }, onContinue: { currentPage = 2 })
                default:
                    if let zone = selectedZone {
                        NotificationSetupView(profile: profile, zone: zone, council: selectedCouncil, address: selectedAddress ?? "", coordinate: selectedCoordinate, onBack: { currentPage = 1 })
                    }
                }
                }
            }
            .background { LinenGround() }
        }
        .tint(Palette.accent)
        .onChange(of: selectedAddress) { _, _ in
            scheduleReviewed = false
            if currentPage == 2 { currentPage = 1 }
        }
        .onAppear {
            selectedAddress = profile.address
            selectedCouncil = DataService.shared.council(for: profile)
            if let latitude = profile.latitude, let longitude = profile.longitude { selectedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
            // Existing ambiguous/parity-only data requires review; it is never guessed into an anchor.
            if profile.hasCompletedOnboarding { currentPage = 1 }
        }
    }
}

/// Three neutral lid spheres; the current step's sphere is lifted off the ground.
struct OnboardingPageIndicator: View {
    let currentPage: Int
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { page in
                LidSphere(bin: nil, size: 8, raised: page == currentPage)
                    .opacity(page == currentPage ? 1 : 0.55)
            }
        }
        .frame(height: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("Page %d of %d", currentPage + 1, 3))
    }
}

/// Back to the previous setup step. Placed in the navigation bar's leading slot, where the
/// system draws it as a Liquid Glass circle.
struct OnboardingBackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(L("Back"), systemImage: "chevron.left")
                .foregroundStyle(Palette.ink)
        }
        .accessibilityLabel(L("Back"))
        .accessibilityHint(L("Return to the previous setup step"))
    }
}
