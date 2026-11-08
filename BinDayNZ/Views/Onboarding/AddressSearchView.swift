import SwiftUI
import MapKit

struct AddressSearchView: View {
    @Binding var selectedZone: CollectionZone?
    @Binding var selectedAddress: String?
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedCouncil: Council?
    @Binding var scheduleReviewed: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    @State private var showSchedule = false
    @State private var councilHint: Council?
    @State private var councilSuggested = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingBackButton(action: onBack)
                Text(L("Set your collection dates")).font(.title.bold())
                Text(L("For council kerbside collections anywhere in New Zealand. Shared bins, private services and rural or island collections may have different arrangements."))
                    .foregroundStyle(.secondary)
                AddressEntryView(address: Binding(get: { selectedAddress ?? "" }, set: { selectedAddress = $0 }), coordinate: $selectedCoordinate, councilHint: $councilHint)
                CouncilRow(council: Binding(get: { selectedCouncil }, set: { selectedCouncil = $0; councilSuggested = false }), suggested: councilSuggested)
                Button { showSchedule = true } label: {
                    Label(selectedZone == nil ? L("Set up manually") : L("Review bin schedule"), systemImage: "calendar")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.borderedProminent).tint(AppTheme.buttonFill)
                if let zone = selectedZone {
                    Label(scheduleReviewed ? L("User-confirmed schedule") : L("Schedule needs confirmation"), systemImage: scheduleReviewed ? "checkmark.circle" : "exclamationmark.circle")
                    ForEach(zone.schedules) { schedule in
                        Label(schedule.binType.displayName, systemImage: schedule.binType.systemImage)
                    }
                }
                NavigationLink(L("Privacy and Help")) { PrivacyView(council: selectedCouncil) }
            }
            .frame(maxWidth: 600, alignment: .leading).padding(24).frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: councilHint) { _, hint in
            // The address only suggests; a council the person chose themselves is kept.
            guard let hint, selectedCouncil == nil || councilSuggested else { return }
            selectedCouncil = hint
            councilSuggested = true
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button(L("Continue"), action: onContinue)
                    .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill).controlSize(.large)
                    .disabled(selectedZone?.isValid != true || !scheduleReviewed || selectedCouncil == nil)
                OnboardingPageIndicator(currentPage: 1)
            }.frame(maxWidth: .infinity).padding().background(.bar)
        }
        .sheet(isPresented: $showSchedule) {
            ManualScheduleView(initialZone: selectedZone, council: selectedCouncil) { selectedZone = $0; scheduleReviewed = true }
        }
    }
}

/// Address is an optional label. A real map appears only for an explicitly resolved location.
struct AddressEntryView: View {
    @Binding var address: String
    @Binding var coordinate: CLLocationCoordinate2D?
    /// Set when a resolved placemark points at one council; cleared when the address changes.
    @Binding var councilHint: Council?
    @StateObject private var search = AddressSearchService()
    @StateObject private var location = LocationManager()
    @State private var resolving = false
    @State private var isVisible = true
    @State private var showSuggestions = false
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Address (optional)")).font(.headline)
            TextField(L("e.g. 12 Queen Street, Auckland"), text: Binding(get: { address }, set: { value in
                address = value; coordinate = nil; councilHint = nil; showSuggestions = true; search.search(value)
            }))
                .textContentType(.fullStreetAddress).autocorrectionDisabled()
                .textFieldStyle(.roundedBorder).focused($focused)
                .disabled(resolving)
            Text(L("An address labels your schedule. It does not set or verify your collection dates."))
                .font(.footnote).foregroundStyle(.secondary)
            if resolving || search.isSearching { ProgressView().accessibilityLabel(L("Finding address")) }
            if showSuggestions {
                ForEach(search.suggestions.prefix(5)) { suggestion in
                    Button {
                        guard !resolving else { return }
                        resolving = true
                        Task { @MainActor in
                            defer { resolving = false }
                            do {
                                let result = try await search.resolve(suggestion)
                                guard isVisible else { return }
                                address = result.fullAddress
                                coordinate = result.coordinate
                                councilHint = result.councilHint
                                showSuggestions = false; focused = false; error = nil
                            } catch { self.error = L("The address could not be found. Enter it yourself or continue without one.") }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(suggestion.title)
                            Text(suggestion.subtitle).font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }.disabled(resolving)
                }
            }
            HStack {
                Button {
                    resolving = true
                    Task { @MainActor in
                        defer { resolving = false }
                        do {
                            guard let value = try await location.requestCurrentLocationAddress() else { throw AddressError.notFound }
                            guard isVisible else { return }
                            address = value; coordinate = nil; councilHint = nil; showSuggestions = true; search.search(value); error = nil
                        } catch { self.error = error.localizedDescription }
                    }
                } label: { Label(L("Use current location"), systemImage: "location") }
                .disabled(resolving)
                if !address.isEmpty {
                    Button(L("Clear")) { address = ""; coordinate = nil; councilHint = nil; showSuggestions = false; search.search("") }.disabled(resolving)
                }
            }.buttonStyle(.bordered).controlSize(.large)
            if let message = error ?? search.errorMessage {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
            if let coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))))
                    .id("\(coordinate.latitude),\(coordinate.longitude)")
                    .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
