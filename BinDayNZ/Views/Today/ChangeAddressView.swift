import SwiftUI
import SwiftData

/// Sheet for changing the user's address.
/// Free-form text field with MapKit autocomplete + collection day zone picker.
struct ChangeAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @StateObject private var searchService = AddressSearchService()
    @StateObject private var locationManager = LocationManager()
    @State private var addressText = ""
    @State private var selectedZoneId: String?
    @FocusState private var isFieldFocused: Bool

    private let dataService = DataService.shared

    private var profile: UserProfile? { profiles.first }

    private var currentCouncil: Council? {
        guard let councilId = profile?.councilId else { return nil }
        return dataService.council(withId: councilId)
    }

    private var zones: [CollectionZone] {
        currentCouncil?.zones ?? []
    }

    private var canSave: Bool {
        !addressText.trimmingCharacters(in: .whitespaces).isEmpty && selectedZoneId != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    
                    // Address input & Autocomplete
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Address")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("e.g. 4 Figaro Street, Ponsonby", text: $addressText)
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
                                                // Resolve address suggestion
                                                if let resolved = await searchService.resolve(suggestion) {
                                                    addressText = resolved.fullAddress
                                                    isFieldFocused = false
                                                    
                                                    // Auto-select zone if matched
                                                    if let matchedZone = resolved.matchedZone,
                                                       zones.contains(where: { $0.id == matchedZone.id }) {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            self.selectedZoneId = matchedZone.id
                                                        }
                                                    }
                                                } else {
                                                    addressText = suggestion.title
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
                                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                                )
                                .padding(.top, 4)
                            }
                            .frame(maxHeight: 250)
                            // Add a transition to make the push-down smooth
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 24)

                    // Collection Day Info (Auto-assigned)
                    if let selectedId = selectedZoneId,
                       let zone = zones.first(where: { $0.id == selectedId }) {
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
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(20)

                Spacer()
            }
            .background(
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isFieldFocused = false
                    }
            )
            .navigationTitle("Change Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.green)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAddress()
                        dismiss()
                    }
                    .foregroundStyle(canSave ? .green : .gray)
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                addressText = profile?.address ?? ""
                selectedZoneId = profile?.zoneId
            }
        }
    }

    private func saveAddress() {
        guard let profile = profile,
              let zoneId = selectedZoneId,
              let zone = zones.first(where: { $0.id == zoneId }) else { return }

        profile.address = addressText.trimmingCharacters(in: .whitespaces)
        profile.zoneId = zoneId

        Task {
            NotificationService.shared.rescheduleUpcoming(zone: zone, profile: profile)
        }
    }
}
