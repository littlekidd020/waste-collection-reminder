import SwiftUI
import MapKit

/// Address entry — third page of onboarding.
/// Free-form text field with MapKit autocomplete + collection day zone picker.
struct AddressSearchView: View {
    let council: Council?
    @Binding var selectedZone: CollectionZone?
    @Binding var selectedAddress: String?
    let onContinue: () -> Void
    let onManualSetup: () -> Void

    @StateObject private var searchService = AddressSearchService()
    @StateObject private var locationManager = LocationManager()
    @State private var addressText = ""
    @FocusState private var isFieldFocused: Bool

    private var zones: [CollectionZone] {
        council?.zones ?? []
    }

    private var canContinue: Bool {
        !addressText.trimmingCharacters(in: .whitespaces).isEmpty && selectedZone != nil
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                if !isFieldFocused {
                    VStack(spacing: 8) {
                        Text(L("Find Your Area"))
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                        Text(L("Enter your address and select your collection day"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    Spacer().frame(height: 20)
                }

                // Address Input & Suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Your Address"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    AddressInputSection(
                        addressText: $addressText,
                        isFieldFocused: $isFieldFocused,
                        locationManager: locationManager,
                        searchService: searchService,
                        onUpdateAddress: { newValue in
                            selectedAddress = newValue.trimmingCharacters(in: .whitespaces)
                        }
                    )

                    if !searchService.suggestions.isEmpty {
                        SuggestionListView(
                            suggestions: searchService.suggestions,
                            searchService: searchService,
                            addressText: $addressText,
                            selectedAddress: $selectedAddress,
                            isFieldFocused: $isFieldFocused,
                            selectedZone: $selectedZone,
                            zones: zones
                        )
                    }
                }
                .zIndex(2)
                .padding(.horizontal, 24)

                // Collection Day Info Box
                if let zone = selectedZone {
                    SelectedZoneInfoView(zoneName: zone.name, zoneId: zone.id)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                }

                Spacer()

                // Action buttons
                if !isFieldFocused {
                    AddressSearchActions(
                        canContinue: canContinue,
                        onContinue: onContinue,
                        onManualSetup: onManualSetup
                    )
                }
            }
        }
        .animation(.default, value: isFieldFocused)
    }
}

// MARK: - Subviews

private struct AddressInputSection: View {
    @Binding var addressText: String
    @FocusState.Binding var isFieldFocused: Bool
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var searchService: AddressSearchService
    let onUpdateAddress: (String) -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(L("e.g. 12 Queen Street, Auckland"), text: $addressText)
                .focused($isFieldFocused)
                .foregroundStyle(.primary)
                .autocorrectionDisabled()
                .padding(.leading, 14)
                .padding(.vertical, 14)
                .padding(.trailing, 44) // Guaranteed gap for the icon
                .onChange(of: addressText) { _, newValue in
                    searchService.search(newValue)
                    onUpdateAddress(newValue)
                }

            InputAccessoryView(
                addressText: $addressText,
                isFieldFocused: $isFieldFocused,
                locationManager: locationManager,
                searchService: searchService
            )
            .frame(width: 44)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isFieldFocused ? Color.green : Color.clear, lineWidth: 2)
                )
        )
    }
}

private struct InputAccessoryView: View {
    @Binding var addressText: String
    @FocusState.Binding var isFieldFocused: Bool
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var searchService: AddressSearchService

    var body: some View {
        if isFieldFocused {
            if !addressText.isEmpty {
                Button {
                    addressText = ""
                    searchService.search("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .padding(12)
                }
            }
        } else {
            Button {
                Task {
                    if let address = try? await locationManager.requestCurrentLocationAddress() {
                        addressText = address
                        searchService.search(address)
                    }
                }
            } label: {
                if locationManager.isRequestingLocation {
                    ProgressView()
                        .padding(12)
                } else {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.green)
                        .padding(12)
                }
            }
        }
    }
}

private struct SuggestionListView: View {
    let suggestions: [AddressSuggestion]
    @ObservedObject var searchService: AddressSearchService
    @Binding var addressText: String
    @Binding var selectedAddress: String?
    @FocusState.Binding var isFieldFocused: Bool
    @Binding var selectedZone: CollectionZone?
    let zones: [CollectionZone]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions) { suggestion in
                    SuggestionRow(
                        suggestion: suggestion,
                        onSelect: {
                            selectSuggestion(suggestion)
                        },
                        isLast: suggestion.id == suggestions.last?.id
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
            .padding(.top, 4)
        }
        .frame(maxHeight: 250)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func selectSuggestion(_ suggestion: AddressSuggestion) {
        Task {
            if let resolved = await searchService.resolve(suggestion) {
                addressText = resolved.fullAddress
                selectedAddress = resolved.fullAddress
                isFieldFocused = false
                
                if let matchedZone = resolved.matchedZone,
                   zones.contains(where: { $0.id == matchedZone.id }) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.selectedZone = matchedZone
                    }
                }
            } else {
                addressText = suggestion.title
                selectedAddress = suggestion.title
                isFieldFocused = false
            }
        }
    }
}

private struct SuggestionRow: View {
    let suggestion: AddressSuggestion
    let onSelect: () -> Void
    let isLast: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        
        if !isLast {
            Divider()
                .padding(.leading, 46)
        }
    }
}

private struct SelectedZoneInfoView: View {
    let zoneName: String
    let zoneId: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: zoneId)
                
            Text(L(zoneName))
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.green.opacity(0.15))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct AddressSearchActions: View {
    let canContinue: Bool
    let onContinue: () -> Void
    let onManualSetup: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onContinue) {
                Text(L("Continue"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(canContinue ? Color.green : Color.gray.opacity(0.3))
                    )
            }
            .disabled(!canContinue)
            .animation(.default, value: canContinue)

            Button(action: onManualSetup) {
                Text(L("Set up manually"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 32)

        // Page indicator
        HStack(spacing: 8) {
            Circle().fill(.quaternary).frame(width: 8, height: 8)
            Circle().fill(.quaternary).frame(width: 8, height: 8)
            Circle().fill(.secondary).frame(width: 8, height: 8)
            Circle().fill(.quaternary).frame(width: 8, height: 8)
        }
        .padding(.bottom, 20)
    }
}
