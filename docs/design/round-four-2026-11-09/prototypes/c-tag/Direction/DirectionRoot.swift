import SwiftUI

/// Direction C, "Tag": a Liquid Glass hang tag on the bin handle carries the date and the bins.
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
                TodayView(frozenSwing: screen == .extra ? 9 : nil)
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

// MARK: - Shared direction pieces

/// Small tracked uppercase label, the direction's only secondary type style.
struct TagLabel: View {
    let text: String
    var size: CGFloat = 12
    var color: Color = Palette.muted
    init(_ text: String, size: CGFloat = 12, color: Color = Palette.muted) {
        self.text = text; self.size = size; self.color = color
    }
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(color)
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

/// Circular Liquid Glass corner button.
struct GlassCornerButton: View {
    let symbol: String
    let label: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.ink)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

/// Eyelet: a small stroked ring, the hole the cord passes through.
struct Eyelet: View {
    var size: CGFloat = 10
    var lineWidth: CGFloat = 1.5
    var color: Color = Palette.muted.opacity(0.7)
    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: lineWidth)
            .background(Circle().fill(Palette.ground.opacity(0.8)).padding(lineWidth))
            .frame(width: size, height: size)
    }
}
