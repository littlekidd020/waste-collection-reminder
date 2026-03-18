import SwiftUI
import SwiftData

/// Settings view — preferences, notifications, calendar, language, and about info.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showAddressSearch = false

    private var profile: UserProfile? { profiles.first }
    private let dataService = DataService.shared

    private var councilName: String {
        guard let id = profile?.councilId else { return String(localized: "Not set") }
        return dataService.council(withId: id)?.name ?? String(localized: "Unknown")
    }

    var body: some View {
        NavigationStack {
            List {
                // Location section
                Section {
                    HStack {
                        Label(String(localized: "Council"), systemImage: "building.2.fill")
                        Spacer()
                        Text(councilName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(String(localized: "Area"), systemImage: "map.fill")
                        Spacer()
                        Text(profile?.address ?? String(localized: "Not set"))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showAddressSearch = true
                    } label: {
                        Label(String(localized: "Change Location"), systemImage: "location.fill")
                    }
                } header: {
                    Text(String(localized: "Location"))
                }

                // Notifications section
                Section {
                    Toggle(isOn: Binding(
                        get: { profile?.notifyEveningBefore ?? true },
                        set: { profile?.notifyEveningBefore = $0; save() }
                    )) {
                        Label(String(localized: "Evening Before"), systemImage: "moon.fill")
                    }

                    if profile?.notifyEveningBefore == true {
                        DatePicker(
                            String(localized: "Time"),
                            selection: Binding(
                                get: { profile?.eveningNotifyTime ?? Date() },
                                set: { profile?.eveningNotifyTime = $0; save() }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }

                    Toggle(isOn: Binding(
                        get: { profile?.notifyMorningOf ?? true },
                        set: { profile?.notifyMorningOf = $0; save() }
                    )) {
                        Label(String(localized: "Morning Of"), systemImage: "sun.max.fill")
                    }

                    if profile?.notifyMorningOf == true {
                        DatePicker(
                            String(localized: "Time"),
                            selection: Binding(
                                get: { profile?.morningNotifyTime ?? Date() },
                                set: { profile?.morningNotifyTime = $0; save() }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text(String(localized: "Notifications"))
                }

                // Calendar section
                Section {
                    Toggle(isOn: Binding(
                        get: { profile?.calendarSyncEnabled ?? false },
                        set: { profile?.calendarSyncEnabled = $0; save() }
                    )) {
                        Label(String(localized: "Sync to Calendar"), systemImage: "calendar.badge.plus")
                    }

                    Button {
                        // TODO: Export .ics file
                    } label: {
                        Label(String(localized: "Export .ics File"), systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text(String(localized: "Calendar"))
                }

                // Language section
                Section {
                    Picker(selection: Binding(
                        get: { profile?.language ?? .english },
                        set: { profile?.language = $0; save() }
                    )) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    } label: {
                        Label(String(localized: "Language"), systemImage: "globe")
                    }
                } header: {
                    Text(String(localized: "Language"))
                }

                // About section
                Section {
                    HStack {
                        Label(String(localized: "Version"), systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://www.aucklandcouncil.govt.nz/rubbish-recycling")!) {
                        Label(String(localized: "Auckland Council Website"), systemImage: "link")
                    }

                    HStack {
                        Label(String(localized: "Made with ♥ in Aotearoa"), systemImage: "heart.fill")
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text(String(localized: "About"))
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddressSearch) {
                // Re-run address search
                Text(String(localized: "Change Location"))
                    .presentationDetents([.large])
            }
        }
    }

    private func save() {
        try? modelContext.save()
    }
}
