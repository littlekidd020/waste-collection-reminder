import SwiftUI

// MARK: - Type

extension View {
    /// Small tracked uppercase label in the secondary colour.
    func kerbLabel(_ size: CGFloat = 13) -> some View {
        self.font(.system(size: size, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Palette.muted)
    }
}

// MARK: - Ground

/// Linen edge to edge with paper grain.
struct LinenGround: View {
    var body: some View {
        ZStack {
            Palette.ground
            Grain(opacity: 0.05)
        }
        .ignoresSafeArea()
    }
}

/// A vertical ease from linen into the deeper surface linen, so props read as standing on a floor.
/// With `returns`, the band eases back to linen below the peak (used for strips that end).
struct GroundBand: View {
    var returns: Bool = false
    /// Where the surface colour peaks, 0...1 (only with `returns`).
    var peak: CGFloat = 0.72

    var body: some View {
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    private var stops: [Gradient.Stop] {
        // the deeper linen laid over the ground with rising opacity, so the paper grain still shows through
        let s = Palette.surface
        func m(_ t: Double) -> Color { s.opacity(t) }
        let g = s.opacity(0)
        if !returns {
            // smoothstep approximated with five stops
            return [.init(color: g, location: 0),
                    .init(color: m(0.10), location: 0.25),
                    .init(color: m(0.50), location: 0.50),
                    .init(color: m(0.90), location: 0.75),
                    .init(color: s, location: 1)]
        }
        let p = peak
        return [.init(color: g, location: 0),
                .init(color: m(0.12), location: p * 0.35),
                .init(color: m(0.62), location: p * 0.7),
                .init(color: s, location: p),
                .init(color: m(0.55), location: p + (1 - p) * 0.45),
                .init(color: g, location: 1)]
    }
}

// MARK: - Props

/// One single-bin prop, laid out so its layout box runs from the top of a full-size wheelie bin to its feet.
/// Every single prop was rendered from one camera on 1024 px tall canvases, so equal `objectHeight` means a
/// shared baseline: bottom-align them and they stand on the same ground. The contact shadow overflows below.
struct BinProp: View {
    let bin: Bin
    /// Height of a full-size wheelie bin at this scale. The food bin and glass crate come out shorter.
    var objectHeight: CGFloat

    static let canvasTop: CGFloat = 252.0 / 1024.0   // top of a wheelie bin handle
    static let canvasFeet: CGFloat = 798.0 / 1024.0  // the wheels touch the ground here

    private var asset: (name: String, aspect: CGFloat) {
        switch bin {
        case .rubbish: return ("bin-rubbish", 418.0 / 1024.0)
        case .recycling: return ("bin-recycling", 417.0 / 1024.0)
        case .foodScraps: return ("bin-food", 314.0 / 1024.0)
        case .glass: return ("crate-glass", 397.0 / 1024.0)
        }
    }

    var body: some View {
        let canvasH = objectHeight / (Self.canvasFeet - Self.canvasTop)
        let canvasW = canvasH * asset.aspect
        Image(asset.name)
            .resizable()
            .scaledToFit()
            .frame(width: canvasW, height: canvasH)
            .offset(y: -canvasH * Self.canvasTop)
            .frame(width: canvasW, height: objectHeight, alignment: .top)
            .accessibilityLabel(bin.name + " bin")
    }

    /// Visible width of the object, used to tighten clusters.
    static func visibleWidth(_ objectHeight: CGFloat) -> CGFloat { objectHeight * 333.0 / 546.0 }
}

/// A little group of bins standing together on one baseline, the back bin set slightly up and smaller for depth.
struct BinCluster: View {
    let bins: [Bin]
    var objectHeight: CGFloat

    var body: some View {
        let w = BinProp.visibleWidth(objectHeight)
        ZStack(alignment: .bottom) {
            if bins.contains(.recycling) {
                // recycling front left, rubbish behind right, food front right: the trio's own arrangement
                BinProp(bin: .rubbish, objectHeight: objectHeight * 0.93)
                    .offset(x: w * 0.38, y: -objectHeight * 0.07)
                BinProp(bin: .recycling, objectHeight: objectHeight)
                    .offset(x: -w * 0.30)
                BinProp(bin: .foodScraps, objectHeight: objectHeight)
                    .offset(x: w * 0.52, y: objectHeight * 0.03)
            } else {
                BinProp(bin: .rubbish, objectHeight: objectHeight * 0.96)
                    .offset(x: -w * 0.16, y: -objectHeight * 0.04)
                BinProp(bin: .foodScraps, objectHeight: objectHeight)
                    .offset(x: w * 0.40, y: objectHeight * 0.02)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Sample.list(bins))
    }
}

/// Bin name paired with its lid sphere, so colour never travels alone.
struct BinCaption: View {
    let bin: Bin
    var body: some View {
        HStack(spacing: 7) {
            LidSphere(bin: bin, size: 10)
            Text(bin.name).kerbLabel(12)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A circular glass corner button with a VoiceOver label.
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
