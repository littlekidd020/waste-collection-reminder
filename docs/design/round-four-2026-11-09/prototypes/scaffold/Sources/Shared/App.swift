import SwiftUI

/// Round-four prototype shell. The screen comes from the launch argument `-screen today|schedule|guide|extra`
/// so every state can be captured deterministically from the command line.
@main
struct RoundFourApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: "en_NZ"))
                .environment(\.timeZone, Sample.timeZone)
                .preferredColorScheme(.light)
        }
    }
}

enum Screen: String, CaseIterable {
    case today, schedule, guide, extra
}

struct RootView: View {
    private var screen: Screen {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-screen"), i + 1 < args.count, let s = Screen(rawValue: args[i + 1]) {
            return s
        }
        return .today
    }

    var body: some View {
        DirectionRoot(screen: screen)
    }
}
