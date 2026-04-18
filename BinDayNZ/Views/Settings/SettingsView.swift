import SwiftUI
import SwiftData

/// Settings view — preferences, notifications, calendar, language, and about info.
struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @State private var showAddressSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    SettingsFormView(profile: profile, showAddressSearch: $showAddressSearch)
                } else {
                    ContentUnavailableView(
                        L("No Profile"),
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(L("Please complete onboarding to access settings."))
                    )
                }
            }
            .navigationTitle(L("Settings"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddressSearch) {
                // Use the new redesigned ChangeAddressView
                ChangeAddressView()
            }
        }
    }
}

/// The settings form subview using standard SwiftUI @Bindable for auto-saving properties
private struct SettingsFormView: View {
    @Bindable var profile: UserProfile
    @Binding var showAddressSearch: Bool

    private let dataService = DataService.shared

    private var councilName: String {
        guard let id = profile.councilId else { return L("Not set") }
        return dataService.council(withId: id)?.name ?? L("Unknown")
    }

    var body: some View {
        List {
            // Location section
            Section {
                HStack {
                    Label(L("Council"), systemImage: "building.2.fill")
                    Spacer()
                    Text(councilName)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label(L("Area"), systemImage: "map.fill")
                    Spacer()
                    Text(profile.address ?? L("Not set"))
                        .foregroundStyle(.secondary)
                }

                Button {
                    showAddressSearch = true
                } label: {
                    Label(L("Change Location"), systemImage: "location.fill")
                }
            } header: {
                Text(L("Location"))
            }

            // Notifications section
            Section {
                Toggle(isOn: $profile.notifyEveningBefore.animation()) {
                    Label(L("Evening Before"), systemImage: "moon.fill")
                }

                if profile.notifyEveningBefore {
                    DatePicker(
                        L("Time"),
                        selection: $profile.eveningNotifyTime,
                        displayedComponents: .hourAndMinute
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Toggle(isOn: $profile.notifyMorningOf.animation()) {
                    Label(L("Morning Of"), systemImage: "sun.max.fill")
                }

                if profile.notifyMorningOf {
                    DatePicker(
                        L("Time"),
                        selection: $profile.morningNotifyTime,
                        displayedComponents: .hourAndMinute
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } header: {
                Text(L("Notifications"))
            }

            // Calendar section
            Section {
                Toggle(isOn: $profile.calendarSyncEnabled) {
                    Label(L("Sync to Calendar"), systemImage: "calendar.badge.plus")
                }

                Button {
                    // TODO: Export .ics file
                } label: {
                    Label(L("Export .ics File"), systemImage: "square.and.arrow.up")
                }
            } header: {
                Text(L("Calendar"))
            }

            // Language section
            Section {
                Picker(selection: $profile.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                } label: {
                    Label(L("Language"), systemImage: "globe")
                }
            } header: {
                Text(L("Language"))
            }

            // About section
            Section {
                HStack {
                    Label(L("Version"), systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "https://www.aucklandcouncil.govt.nz/rubbish-recycling")!) {
                    Label(L("Auckland Council Website"), systemImage: "link")
                }

                HStack {
                    Label(L("Made with ♥ in Aotearoa"), systemImage: "heart.fill")
                        .foregroundStyle(.primary)
                }
            } header: {
                Text(L("About"))
            }
        }
    }
}
