import SwiftUI
import SwiftData

/// The app entry point. Sets up SwiftData model container and determines
/// whether to show onboarding or the main tab view.
@main
struct BinDayNZApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: UserProfile.self)
    }
}
