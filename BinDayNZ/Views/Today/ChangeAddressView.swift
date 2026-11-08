import SwiftUI
import SwiftData
import CoreLocation

struct ChangeAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @State private var address = ""
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var council: Council?
    @State private var councilHint: Council?
    @State private var councilSuggested = false
    @State private var zone: CollectionZone?
    @State private var showSchedule = false
    @State private var saving = false
    @State private var initialized = false
    @State private var reviewed = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AddressEntryView(address: $address, coordinate: $coordinate, councilHint: $councilHint)
                    CouncilRow(council: Binding(get: { council }, set: { council = $0; councilSuggested = false; reviewed = false }), suggested: councilSuggested)
                    Button { showSchedule = true } label: {
                        Label(L("Review bin schedule"), systemImage: "calendar")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.borderedProminent).tint(AppTheme.buttonFill)
                    if let zone {
                        ForEach(zone.schedules) { schedule in
                            Label(schedule.binType.displayName, systemImage: schedule.binType.systemImage)
                        }
                    }
                    Text(L("Review the dates whenever your property or collection service changes."))
                        .foregroundStyle(.secondary)
                    if let error { Text(error).foregroundStyle(.red) }
                    if saving { ProgressView(L("Saving schedule")) }
                }.frame(maxWidth: 600, alignment: .leading).padding(24).frame(maxWidth: .infinity)
            }
            .navigationTitle(L("Change schedule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("Cancel")) { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) { Task { await save() } }
                        .disabled(saving || !reviewed || zone?.isValid != true || council == nil)
                }
            }
            .interactiveDismissDisabled(saving)
            .onAppear {
                guard !initialized, let profile = profiles.first else { return }
                initialized = true
                address = profile.address ?? ""
                if let latitude = profile.latitude, let longitude = profile.longitude { coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
                zone = DataService.shared.zone(for: profile)
                council = DataService.shared.council(for: profile)
            }
            .onChange(of: address) { _, _ in reviewed = false }
            .onChange(of: councilHint) { _, hint in
                guard let hint, council == nil || councilSuggested else { return }
                council = hint; councilSuggested = true; reviewed = false
            }
            .sheet(isPresented: $showSchedule) {
                ManualScheduleView(initialZone: zone, council: council) { zone = $0; reviewed = true }
            }
        }
    }

    @MainActor private func save() async {
        guard let profile = profiles.first, let zone else { return }
        saving = true
        defer { saving = false }
        do {
            try await ScheduleCoordinator.shared.save(zone: zone, council: council, address: address, coordinate: coordinate, profile: profile, context: context)
            dismiss() // Integration errors are visible in Today/Settings; the schedule did save.
        } catch { self.error = L("Your schedule could not be saved. Please try again.") }
    }
}
