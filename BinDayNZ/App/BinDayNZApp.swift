import SwiftUI
import SwiftData

@main
struct BinDayNZApp: App {
    private let container: ModelContainer?

    init() {
        container = try? ModelContainer(for: UserProfile.self)
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView().modelContainer(container)
            } else {
                NavigationStack {
                ContentUnavailableView {
                    Label(L("Saved data is unavailable"), systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(L("Bin Day NZ could not open its saved information. Free some device storage and reopen the app. Your data has not been reset. Use Privacy and Help for support."))
                } actions: {
                    NavigationLink(L("Privacy and Help")) { PrivacyView() }
                }
                }
            }
        }
    }
}
