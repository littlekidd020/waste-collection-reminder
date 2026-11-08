import SwiftUI

/// A matte clay torus lit from the upper left. `outer` is the outside diameter, `tube` the stroke width.
/// `draw` trims every layer together (clockwise from twelve) so the ring can draw itself.
/// `fill` is an optional dyed arc (from twelve, as a fraction of the ring) laid into the clay under the lighting.
struct TorusRing: View {
    var outer: CGFloat
    var tube: CGFloat
    var draw: CGFloat = 1
    var fill: (color: Color, to: CGFloat, roundCap: Bool)? = nil
    var shadowRadius: CGFloat = 18
    var shadowY: CGFloat = 10
    var shadowOpacity: Double = 0.12

    private var mid: CGFloat { outer - tube }          // diameter of the stroke centre line
    private var rIn: CGFloat { (outer - tube * 2) / 2 }
    private var rOut: CGFloat { outer / 2 }

    private func tubeGradient(_ stops: [Gradient.Stop]) -> RadialGradient {
        RadialGradient(gradient: Gradient(stops: stops), center: .center, startRadius: rIn, endRadius: rOut)
    }

    /// Trimmed circle starting at twelve o'clock; the shape is rotated, not the view, so lighting stays in screen space.
    private func arc(_ to: CGFloat) -> some Shape {
        Circle().trim(from: 0, to: to).rotation(.degrees(-90))
    }

    var body: some View {
        ZStack {
            // 1. Clay body: edges fall off into ambient occlusion, the crown of the tube is lighter.
            arc(draw)
                .stroke(tubeGradient([
                    .init(color: Palette.surface.darker(0.16), location: 0),
                    .init(color: Palette.surface.darker(0.03), location: 0.22),
                    .init(color: Palette.surface.lighter(0.10), location: 0.52),
                    .init(color: Palette.surface, location: 0.80),
                    .init(color: Palette.surface.darker(0.11), location: 1)
                ]), style: StrokeStyle(lineWidth: tube, lineCap: .butt))
                .frame(width: mid, height: mid)
                .shadow(color: Palette.shadow.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
                .shadow(color: Palette.shadow.opacity(0.07), radius: 2, x: 0, y: 1.5)

            // 2. Dyed arc, if any.
            if let fill {
                arc(min(fill.to, draw))
                    .stroke(fill.color, style: StrokeStyle(lineWidth: tube, lineCap: fill.roundCap ? .round : .butt))
                    .frame(width: mid, height: mid)
            }

            // 3. Global light: upper left warmer and brighter, lower right in its own shade.
            arc(draw)
                .stroke(LinearGradient(stops: [
                    .init(color: .white.opacity(0.30), location: 0),
                    .init(color: .white.opacity(0.0), location: 0.45),
                    .init(color: Palette.shadow.opacity(0.0), location: 0.55),
                    .init(color: Palette.shadow.opacity(0.16), location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: tube)
                .frame(width: mid, height: mid)

            // 4. Specular band on the outer shoulder, seen only where it faces the light (upper left).
            arc(draw)
                .stroke(tubeGradient([
                    .init(color: .white.opacity(0), location: 0.45),
                    .init(color: .white.opacity(0.42), location: 0.66),
                    .init(color: .white.opacity(0), location: 0.88)
                ]), lineWidth: tube)
                .frame(width: mid, height: mid)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .topLeading, endPoint: UnitPoint(x: 0.62, y: 0.62)))

            // 5. Specular band on the inner wall, which faces the light on the lower right.
            arc(draw)
                .stroke(tubeGradient([
                    .init(color: .white.opacity(0), location: 0.08),
                    .init(color: .white.opacity(0.30), location: 0.28),
                    .init(color: .white.opacity(0), location: 0.5)
                ]), lineWidth: tube)
                .frame(width: mid, height: mid)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .bottomTrailing, endPoint: UnitPoint(x: 0.4, y: 0.4)))

            // 6. 1 pt rim highlights: outer edge upper left, inner edge lower right.
            arc(draw)
                .stroke(LinearGradient(colors: [.white.opacity(0.85), .white.opacity(0)], startPoint: .topLeading, endPoint: UnitPoint(x: 0.7, y: 0.7)), lineWidth: 1)
                .frame(width: outer - 1.5, height: outer - 1.5)
            arc(draw)
                .stroke(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0)], startPoint: .bottomTrailing, endPoint: UnitPoint(x: 0.35, y: 0.35)), lineWidth: 1)
                .frame(width: rIn * 2 + 1.5, height: rIn * 2 + 1.5)
        }
        .frame(width: outer, height: outer)
    }
}
