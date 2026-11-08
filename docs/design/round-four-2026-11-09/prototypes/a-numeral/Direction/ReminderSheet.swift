import SwiftUI

struct ReminderSheet: View {
    @State private var choice = 0

    private let options: [(title: String, caption: String)] = [
        ("7 pm tonight", "The evening before"),
        ("6 am tomorrow", "An hour before the truck"),
        ("Both", "Evening and morning")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Remind me")
                .eyebrow(13)
                .padding(.top, 32)
                .padding(.bottom, 12)
            ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { choice = i }
                } label: {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title)
                                .font(.system(size: 28, weight: .light))
                                .monospacedDigit()
                                .foregroundStyle(choice == i ? Palette.ink : Palette.muted)
                            Text(option.caption)
                                .eyebrow(12)
                        }
                        Spacer()
                        if choice == i {
                            AccentSphere(size: 20)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 12)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(choice == i ? .isSelected : [])
                if i < options.count - 1 {
                    Rectangle().fill(Palette.line).frame(height: 0.5)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .background(Palette.ground.opacity(0.55).ignoresSafeArea())
    }
}

/// The moss accent rendered in the same matte material as the lid spheres.
struct AccentSphere: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Palette.shadow.opacity(0.28))
                .frame(width: size * 0.9, height: size * 0.32)
                .blur(radius: size * 0.12)
                .offset(y: size * 0.46)
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Palette.accent.lighter(0.28), location: 0),
                        .init(color: Palette.accent, location: 0.45),
                        .init(color: Palette.accent.darker(0.35), location: 1)
                    ]),
                    center: UnitPoint(x: 0.36, y: 0.30), startRadius: 0, endRadius: size * 0.62))
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
