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
                        Text(String(localized: "Find Your Area"))
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                        Text(String(localized: "Enter your address and select your collection day"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    Spacer().frame(height: 20)
                }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Address")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("e.g. 12 Queen Street, Auckland", text: $addressText)
                            .focused($isFieldFocused)
                            .foregroundStyle(.primary)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(isFieldFocused ? Color.green : Color.clear, lineWidth: 2)
                                    )
                            )
                            .onChange(of: addressText) { _, newValue in
                                searchService.search(newValue)
                                selectedAddress = newValue.trimmingCharacters(in: .whitespaces)
                            }
                            // Right accessories: clear button when focused, location button when unfocused
                            .overlay(alignment: .trailing) {
                                if isFieldFocused {
                                    if !addressText.isEmpty {
                                        Button {
                                            addressText = ""
                                            searchService.search("")
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.tertiary)
                                                .padding()
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
                                                .padding()
                                        } else {
                                            Image(systemName: "location.fill")
                                                .foregroundStyle(.green)
                                                .padding()
                                        }
                                    }
                                }
                            }
                        // Autocomplete suggestions
                        if !searchService.suggestions.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(searchService.suggestions) { suggestion in
                                        Button {
                                            Task {
                                                // Resolve the address suggestion
                                                if let resolved = await searchService.resolve(suggestion) {
                                                    addressText = resolved.fullAddress
                                                    selectedAddress = resolved.fullAddress
                                                    isFieldFocused = false
                                                    
                                                    // Auto-select zone if matched
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
                                        } label: {
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
                                        
                                        if suggestion.id != searchService.suggestions.last?.id {
                                            Divider()
                                                .padding(.leading, 46)
                                        }
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
                            // Add a transition to make the push-down smooth
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .zIndex(2) // keep floating dropdown on top of views below
                .padding(.horizontal, 24)

                    // Collection Day Info Box (Auto-assigned)
                    if let zone = selectedZone {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundStyle(.green)
                                .symbolEffect(.bounce, value: zone.id)
                                
                            Text(zone.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.green.opacity(0.15))
                        )
                        .padding(.top, 10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                Spacer()

                // Action buttons
                if !isFieldFocused {
                    VStack(spacing: 12) {
                        Button(action: onContinue) {
                            Text(String(localized: "Continue"))
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
                            Text(String(localized: "Set up manually"))
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
        }
        .animation(.default, value: isFieldFocused)
    }
}
