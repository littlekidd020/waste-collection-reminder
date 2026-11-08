import SwiftUI

/// Direction D, "Kerb": the household's real bins stand on the linen ground and are the interface.
struct DirectionRoot: View {
    let screen: Screen
    @State private var tab: Screen

    init(screen: Screen) {
        self.screen = screen
        _tab = State(initialValue: screen == .extra ? .today : screen)
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "sun.horizon", value: Screen.today) {
                TodayView(frozenAtKerb: screen == .extra)
            }
            Tab("Schedule", systemImage: "calendar", value: Screen.schedule) {
                ScheduleView()
            }
            Tab("Guide", systemImage: "book", value: Screen.guide) {
                GuideView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Palette.accent)
    }
}
