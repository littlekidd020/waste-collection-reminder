import SwiftUI

/// The brand's physical unit: a matte sphere in a lid colour, lit from the upper left like the app icon.
/// Use it for day markers, bin markers and beads. `size` is the diameter in points.
struct LidSphere: View {
    var bin: Bin?
    var size: CGFloat = 28
    var raised: Bool = false

    private var base: Color { bin?.lid ?? Color(hex: 0xEDE8DF) }

    var body: some View {
        ZStack {
            // contact shadow
            Ellipse()
                .fill(Palette.shadow.opacity(raised ? 0.22 : 0.30))
                .frame(width: size * 0.9, height: size * 0.32)
                .blur(radius: size * 0.12)
                .offset(y: size * (raised ? 0.62 : 0.46))
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: base.lighter(0.22), location: 0),
                            .init(color: base, location: 0.38),
                            .init(color: base.darker(0.18), location: 0.78),
                            .init(color: base.darker(0.38), location: 1)
                        ]),
                        center: UnitPoint(x: 0.36, y: 0.30),
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )
                .overlay(
                    Circle().fill(
                        LinearGradient(colors: [.clear, Palette.shadow.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                    )
                )
                .frame(width: size, height: size)
                .offset(y: raised ? -size * 0.16 : 0)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(bin?.name ?? "Day")
    }
}

extension Color {
    func lighter(_ amount: Double) -> Color { mix(with: .white, amount) }
    func darker(_ amount: Double) -> Color { mix(with: Color(hex: 0x1E1A16), amount) }

    private func mix(with other: Color, _ t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(.sRGB, red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, opacity: 1)
    }
}

/// Subtle paper grain for the linen ground. Keep opacity between 0.04 and 0.07.
struct Grain: View {
    var opacity: Double = 0.05
    var body: some View {
        Canvas { context, size in
            var rng = SystemRandomNumberGenerator()
            let count = Int(size.width * size.height / 22)
            for _ in 0..<count {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let dark = Bool.random(using: &rng)
                context.fill(Path(CGRect(x: x, y: y, width: 0.6, height: 0.6)),
                             with: .color((dark ? Palette.ink : .white).opacity(opacity * 0.8)))
            }
        }
        .allowsHitTesting(false)
        .drawingGroup()
    }
}
