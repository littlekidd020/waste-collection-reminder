import SwiftUI
import SwiftData
import MapKit

/// Sheet for changing the user's address.
/// Uber-style layout: map fills the top, content card anchored at bottom.
struct ChangeAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @StateObject private var searchService = AddressSearchService()
    @StateObject private var locationManager = LocationManager()
    @State private var addressText = ""
    @State private var selectedZoneId: String?
    @State private var resolvedCoordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
    )
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
                // ── Top: Map ──
                mapSection
                
                // ── Bottom: Content card ──
                bottomCard
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .foregroundStyle(.green)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveAddress()
                        dismiss()
                    }
                    .foregroundStyle(canSave ? .green : .gray)
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .onAppear {
                addressText = profile?.address ?? ""
                selectedZoneId = profile?.zoneId
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map(position: $mapPosition) {
            if let coord = resolvedCoordinate {
                Annotation("", coordinate: coord) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.green)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 20, height: 20)
                            )

                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                            .offset(y: -3)
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .allowsHitTesting(false)
        .overlay(alignment: .bottom) {
            // Gradient fade into the card
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground).opacity(0),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
        }
    }

    // MARK: - Bottom Card

    private var bottomCard: some View {
        VStack(spacing: 16) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(uiColor: .tertiaryLabel))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            // Title
            Text(L("Change Address"))
                .font(.headline)

            Divider()
                .padding(.horizontal, -20) // bleed edge-to-edge

            // Address input & autocomplete
            addressInputSection
            
            // Collection Day Badge
            collectionDayBadge
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
            .fill(Color(uiColor: .systemGroupedBackground))
            .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
    }

    // MARK: - Address Input Section

    private var addressInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("Your Address"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ZStack(alignment: .trailing) {
                TextField(L("e.g. 4 Figaro Street, Ponsonby"), text: $addressText)
                    .focused($isFieldFocused)
                    .foregroundStyle(.primary)
                    .autocorrectionDisabled()
                    .padding(.leading, 14)
                    .padding(.vertical, 14)
                    .padding(.trailing, 44)
                    .onChange(of: addressText) { _, newValue in
                        searchService.search(newValue)
                    }

                if isFieldFocused {
                    if !addressText.isEmpty {
                        Button {
                            addressText = ""
                            searchService.search("")
                            clearMapPin()
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
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isFieldFocused ? Color.green : Color.clear, lineWidth: 2)
                    )
            )

            // Autocomplete suggestions
            if !searchService.suggestions.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchService.suggestions) { suggestion in
                            Button {
                                Task {
                                    if let resolved = await searchService.resolve(suggestion) {
                                        addressText = resolved.fullAddress
                                        isFieldFocused = false

                                        // Update map
                                        updateMapPin(to: resolved.coordinate)

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
                .frame(maxHeight: 200)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Collection Day Badge

    @ViewBuilder
    private var collectionDayBadge: some View {
        if let selectedId = selectedZoneId,
           let zone = zones.first(where: { $0.id == selectedId }) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: zone.id)

                Text(L(zone.name))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.green.opacity(0.12))
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Map Helpers

    private func updateMapPin(to coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            resolvedCoordinate = coordinate
            mapPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }

    private func clearMapPin() {
        withAnimation(.easeInOut(duration: 0.3)) {
            resolvedCoordinate = nil
            mapPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633),
                    span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
                )
            )
        }
    }

    // MARK: - Save

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
