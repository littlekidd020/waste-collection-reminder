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
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L("Set your collection dates"))
                        .kerbFont(28, .semibold, relativeTo: .title)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(L("For council kerbside collections anywhere in New Zealand. Shared bins, private services and rural or island collections may have different arrangements."))
                        .kerbFont(17, relativeTo: .body)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                AddressEntryView(address: Binding(get: { selectedAddress ?? "" }, set: { selectedAddress = $0 }), coordinate: $selectedCoordinate, councilHint: $councilHint)
                CouncilRow(council: Binding(get: { selectedCouncil }, set: { selectedCouncil = $0; councilSuggested = false }), suggested: councilSuggested)
                VStack(alignment: .leading, spacing: 16) {
                    // The step's one prominent action: setting up the schedule, then Continue once it is confirmed.
                    if selectedZone == nil {
                        Button { showSchedule = true } label: {
                            KerbPrimaryButtonLabel(title: L("Set up manually"), systemImage: "calendar")
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Palette.accent)
                    } else {
                        Button { showSchedule = true } label: {
                            KerbPrimaryButtonLabel(title: L("Review bin schedule"), systemImage: "calendar", prominent: false)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.capsule)
                    }
                    if let zone = selectedZone {
                        Label {
                            Text(scheduleReviewed ? L("User-confirmed schedule") : L("Schedule needs confirmation"))
                                .foregroundStyle(scheduleReviewed ? Palette.ink : Palette.attention)
                        } icon: {
                            Image(systemName: scheduleReviewed ? "checkmark.circle" : "exclamationmark.circle")
                                .foregroundStyle(scheduleReviewed ? Palette.accent : Palette.attention)
                        }
                        .kerbFont(15, .medium, relativeTo: .subheadline)
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(zone.schedules) { schedule in
                                CollectionBinRow(bin: schedule.binType)
                            }
                        }
                    }
                }
                Hairline()
                NavigationLink(L("Privacy and Help")) { PrivacyView(council: selectedCouncil) }
                    .kerbFont(15, relativeTo: .subheadline)
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: 600, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background { LinenGround() }
        .tint(Palette.accent)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { OnboardingBackButton(action: onBack) }
        }
        .onChange(of: councilHint) { _, hint in
            // The address only suggests; a council the person chose themselves is kept.
            guard let hint, selectedCouncil == nil || councilSuggested else { return }
            selectedCouncil = hint
            councilSuggested = true
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    KerbPrimaryButtonLabel(title: L("Continue"))
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(Palette.accent)
                .disabled(selectedZone?.isValid != true || !scheduleReviewed || selectedCouncil == nil)
                OnboardingPageIndicator(currentPage: 1)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                LinearGradient(colors: [Palette.ground.opacity(0), Palette.ground.opacity(0.94)],
                               startPoint: .top, endPoint: .init(x: 0.5, y: 0.35))
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
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
            Text(L("Address (optional)")).kerbLabel()
            TextField(L("e.g. 12 Queen Street, Auckland"), text: Binding(get: { address }, set: { value in
                address = value; coordinate = nil; councilHint = nil; showSuggestions = true; search.search(value)
            }))
                .textContentType(.fullStreetAddress).autocorrectionDisabled()
                .focused($focused)
                .kerbFont(17, relativeTo: .body)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(Palette.surface, in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(focused ? Palette.accent.opacity(0.6) : Palette.line, lineWidth: focused ? 1 : 0.5) }
                .disabled(resolving)
            Text(L("An address labels your schedule. It does not set or verify your collection dates."))
                .kerbFootnote()
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .kerbFont(17, relativeTo: .body)
                                .foregroundStyle(Palette.ink)
                            Text(suggestion.subtitle)
                                .kerbFont(13, relativeTo: .footnote)
                                .foregroundStyle(Palette.muted)
                        }
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(resolving)
                    Hairline()
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
            }
            .buttonStyle(.glass).buttonBorderShape(.capsule).controlSize(.large)
            .kerbFont(15, .medium, relativeTo: .subheadline)
            .foregroundStyle(Palette.ink)
            if let message = error ?? search.errorMessage {
                Text(message)
                    .kerbFont(13, relativeTo: .footnote)
                    .foregroundStyle(Palette.attention)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))))
                    .id("\(coordinate.latitude),\(coordinate.longitude)")
                    .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 14)).accessibilityHidden(true)
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
