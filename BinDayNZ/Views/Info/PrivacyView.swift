import SwiftUI

/// Bundled disclosure and help remain readable without a connection.
struct PrivacyView: View {
    var council: Council? = nil

    var body: some View {
        List {
            Section {
                Text(L("Your schedule, reminder preferences, language and any saved address or map coordinates are stored on this device. Bin Day NZ does not send your saved profile to a developer-run service or sync it through iCloud."))
                Text(L("The home screen widget shares collection dates and your chosen language with the app. It does not need your home address."))
                Text(L("Use Remove saved data in Settings to review and clear the app's saved information."))
            } header: { KerbSectionHeader(L("Saved on this device")) }
            .kerbFormRows()

            Section {
                Text(L("Address search uses Apple Maps, which receives search requests. Using your current location is optional and requires your permission; you can enter a schedule manually instead."))
                Text(L("Council links open the official website in your browser. The app does not upload your saved address to your council."))
            } header: { KerbSectionHeader(L("Address and location search")) }
            .kerbFormRows()

            Section {
                Text(L("Reminders are scheduled on your device and depend on notification permission and your system settings. You can change them in Settings."))
                Text(L("Calendar access is optional. Events added to a calendar may sync through that calendar's provider. Exported calendar files are separate copies and do not update automatically."))
                Text(L("Calendar events from earlier app versions cannot be identified safely by this version. Review and remove any old Bin Day events yourself in Calendar if they are no longer correct."))
            } header: { KerbSectionHeader(L("Reminders and calendars")) }
            .kerbFormRows()

            Section {
                Text(L("Reading a bin guide does not load YouTube. Choosing Load video connects to YouTube using its privacy-enhanced player and a temporary web session. YouTube may receive network and device information when it loads. Opening YouTube separately uses that app or browser's privacy settings."))
                Link(L("YouTube privacy information"), destination: URL(string: "https://policies.google.com/privacy")!)
                    .foregroundStyle(.tint)
            } header: { KerbSectionHeader(L("Optional YouTube videos")) }
            .kerbFormRows()

            Section {
                Text(L("For an incorrect app schedule or a problem with the app, report an issue on GitHub. A GitHub account is required and reports are public. Do not include your full home address or other private information."))
                Link(destination: URL(string: "https://github.com/littlekidd020/waste-collection-reminder/issues")!) {
                    Label(L("Report an app issue"), systemImage: "arrow.up.right.square")
                }
                    .foregroundStyle(.tint)
                if let council {
                    Text(L("For a missed collection or council service question, contact %@.", council.name))
                    if let phoneURL = council.phoneURL {
                        Link(destination: phoneURL) { Label(L("Call %@", council.name), systemImage: "phone") }
                        .foregroundStyle(.tint)
                    }
                    Link(destination: council.website) { Label(L("Council website"), systemImage: "globe") }
                    .foregroundStyle(.tint)
                } else {
                    Text(L("For a missed collection or council service question, contact your council."))
                }
            } header: { KerbSectionHeader(L("Get help")) }
            .kerbFormRows()
        }
        .navigationTitle(L("Privacy and Help"))
        .navigationBarTitleDisplayMode(.inline)
        .kerbFormGround()
    }
}
