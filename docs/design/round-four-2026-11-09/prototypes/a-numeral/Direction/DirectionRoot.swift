import SwiftUI

/// Direction A, "Numeral": the day is a number. Three glass tabs over a linen ground.
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
                TodayView(showReminderSheet: screen == .extra)
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

// MARK: - Shared pieces for this direction

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

extension View {
    /// Small tracked uppercase label in the secondary colour.
    func eyebrow(_ size: CGFloat = 12) -> some View {
        self.font(.system(size: size, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Palette.muted)
    }

    /// Entrance: settle in from below with the house spring.
    func settle(_ shown: Bool, delay: Double, reduce: Bool, from dy: CGFloat = 24) -> some View {
        modifier(Settle(shown: shown, delay: delay, reduce: reduce, dy: dy))
    }
}

struct Settle: ViewModifier {
    let shown: Bool
    let delay: Double
    let reduce: Bool
    let dy: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: (shown || reduce) ? 0 : dy)
            .animation(reduce ? .easeOut(duration: 0.25) : .spring(response: 0.6, dampingFraction: 0.85).delay(delay), value: shown)
    }
}

/// A sphere that drops onto the ground and squashes a little on landing.
struct DropIn: ViewModifier {
    let shown: Bool
    let delay: Double
    let reduce: Bool
    @State private var squash = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: squash ? 1.07 : 1, y: squash ? 0.9 : 1, anchor: .bottom)
            .opacity(shown ? 1 : 0)
            .offset(y: (shown || reduce) ? 0 : -28)
            .animation(reduce ? .easeOut(duration: 0.25) : .spring(response: 0.45, dampingFraction: 0.9).delay(delay), value: shown)
            .onChange(of: shown) { _, now in
                guard now, !reduce else { return }
                Task {
                    try? await Task.sleep(for: .seconds(delay + 0.26))
                    withAnimation(.easeOut(duration: 0.07)) { squash = true }
                    try? await Task.sleep(for: .seconds(0.08))
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) { squash = false }
                }
            }
    }
}

/// Circular glass corner button with a VoiceOver label.
struct GlassCircleButton: View {
    let symbol: String
    let label: String
    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}
