import SwiftUI

/// The brand's physical unit: a matte sphere in a lid colour, lit from the upper left like the app
/// icon. Marks a bin wherever its name is nearby (captions, calendar days, widget rows).
/// `size` is the diameter in points. Shared with the widget.
struct LidSphere: View {
    var bin: BinType?
    var size: CGFloat = 12
    /// Lifted off the ground, for the current page or a selected day.
    var raised: Bool = false

    private var base: Color { bin?.lidTone ?? Color(hex: 0xC9C0B2) }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Palette.shadow.opacity(raised ? 0.18 : 0.26))
                .frame(width: size * 0.85, height: size * 0.28)
                .blur(radius: size * 0.09)
                .offset(y: size * (raised ? 0.60 : 0.44))
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: base.lighter(0.30), location: 0),
                            .init(color: base.lighter(0.06), location: 0.30),
                            .init(color: base.darker(0.16), location: 0.74),
                            .init(color: base.darker(0.40), location: 1)
                        ]),
                        center: UnitPoint(x: 0.34, y: 0.28),
                        startRadius: 0,
                        endRadius: size * 0.60
                    )
                )
                .frame(width: size, height: size)
                .offset(y: raised ? -size * 0.16 : 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
