import SwiftUI

enum DialTab: Hashable { case today, schedule, guide }

/// Direction B, "Dial": the fortnight is an instrument.
struct DirectionRoot: View {
    let screen: Screen
    @State private var tab: DialTab

    init(screen: Screen) {
        self.screen = screen
        switch screen {
        case .today, .extra: _tab = State(initialValue: .today)
        case .schedule: _tab = State(initialValue: .schedule)
        case .guide: _tab = State(initialValue: .guide)
        }
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "sun.horizon", value: DialTab.today) {
                TodayDialView(frozenScrubDay: screen == .extra ? 5 : nil)
            }
            Tab("Schedule", systemImage: "calendar", value: DialTab.schedule) {
                ScheduleThreadView()
            }
            Tab("Guide", systemImage: "book", value: DialTab.guide) {
                GuideGaugesView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Palette.accent)
    }
}

/// Linen ground with paper grain, edge to edge.
struct LinenGround: View {
    var body: some View {
        ZStack {
            Palette.ground
            Grain(opacity: 0.05)
        }
        .ignoresSafeArea()
    }
}

/// The tracked uppercase label used everywhere.
struct Eyebrow: View {
    let text: String
    var color: Color = Palette.muted
    init(_ text: String, color: Color = Palette.muted) { self.text = text; self.color = color }
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(color)
    }
}
