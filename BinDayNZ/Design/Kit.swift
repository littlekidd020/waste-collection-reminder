import SwiftUI

// MARK: - Type

/// A point size that follows Dynamic Type, relative to a text style, capped so display sizes stay
/// composed at accessibility settings. Body copy uses the system text styles directly.
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// Crafted type sizes that still scale: 44 verdict, 34 numeral, 17 body, 15 secondary, 13/12 labels.
    func kerbFont(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, relativeTo: style, design: design))
    }

    /// Small tracked uppercase label in the secondary colour.
    func kerbLabel(_ size: CGFloat = 13) -> some View {
        self.kerbFont(size, .semibold, relativeTo: .footnote)
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Palette.muted)
    }
}

// MARK: - Ground

/// Linen edge to edge with paper grain. The base layer of every screen.
struct LinenGround: View {
    var body: some View {
        ZStack {
            Palette.ground
            Grain()
        }
        .ignoresSafeArea()
    }
}

/// A vertical ease from the ground into the deeper surface linen, so props read as standing on a
/// floor. With `returns`, the band eases back out below the peak (for strips that end).
struct GroundBand: View {
    var returns: Bool = false
    /// Where the surface colour peaks, 0...1 (only with `returns`).
    var peak: CGFloat = 0.72

    var body: some View {
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            .allowsHitTesting(false)
    }

    private var stops: [Gradient.Stop] {
        let s = Palette.surface
        func m(_ t: Double) -> Color { s.opacity(t) }
        let clear = s.opacity(0)
        if !returns {
            return [.init(color: clear, location: 0),
                    .init(color: m(0.10), location: 0.25),
                    .init(color: m(0.50), location: 0.50),
                    .init(color: m(0.90), location: 0.75),
                    .init(color: s, location: 1)]
        }
        let p = peak
        return [.init(color: clear, location: 0),
                .init(color: m(0.12), location: p * 0.35),
                .init(color: m(0.62), location: p * 0.7),
                .init(color: s, location: p),
                .init(color: m(0.55), location: p + (1 - p) * 0.45),
                .init(color: clear, location: 1)]
    }
}

/// Subtle paper grain. Seeded, so it never shimmers between redraws.
struct Grain: View {
    var opacity: Double = 0.05

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var rng = SplitMix64(seed: 0x6B65726273696465)
            let count = Int(size.width * size.height / 22)
            let dark = Palette.ink.opacity(opacity * 0.8)
            let light = Color.white.opacity(opacity * 0.8)
            for _ in 0..<count {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                context.fill(Path(CGRect(x: x, y: y, width: 0.6, height: 0.6)),
                             with: .color(Bool.random(using: &rng) ? dark : light))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// A half-point rule in the line colour.
struct Hairline: View {
    var body: some View {
        Rectangle().fill(Palette.line).frame(height: 0.5)
    }
}

// MARK: - Chrome

/// A circular Liquid Glass corner button with a VoiceOver label.
struct GlassCircleButton: View {
    let systemImage: String
    let label: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}

/// Shared press feedback that respects Reduce Motion.
struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.78 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Lays children out in rows, wrapping like words. For captions that may not fit one line.
struct FlowLayout: Layout {
    var spacing: CGFloat = 16
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0; y += rowHeight + rowSpacing; rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }
        return CGSize(width: width == .infinity ? maxX : min(width, maxX), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Each row is measured first so it can be centred inside the bounds.
        var rows: [[(LayoutSubview, CGSize)]] = [[]]
        var x: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > bounds.width {
                rows.append([]); x = 0
            }
            rows[rows.count - 1].append((view, size))
            x += size.width + spacing
        }
        var y = bounds.minY
        for row in rows {
            let rowWidth = row.reduce(0) { $0 + $1.1.width } + spacing * CGFloat(max(0, row.count - 1))
            let rowHeight = row.map(\.1.height).max() ?? 0
            var rx = bounds.minX + (bounds.width - rowWidth) / 2
            for (view, size) in row {
                view.place(at: CGPoint(x: rx, y: y + (rowHeight - size.height) / 2), proposal: ProposedViewSize(size))
                rx += size.width + spacing
            }
            y += rowHeight + rowSpacing
        }
    }
}

/// Bin name paired with its lid sphere, so colour never travels alone.
struct BinCaption: View {
    let bin: BinType
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 7) {
            LidSphere(bin: bin, size: size * 0.85)
            Text(bin.displayName).kerbLabel(size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bin.displayName)
    }
}
