import SwiftUI
import UIKit

// MARK: - Prop geometry

/// Every single prop is normalised by `scripts/key-props.py` so that a full-size wheelie bin spans
/// 20 % to 80 % of its canvas height with its wheels on the 80 % line. Smaller objects sit on the
/// same line at their real size. Bottom-align props of one `objectHeight` and they stand together.
enum PropGeometry {
    static let canvasTop: CGFloat = 0.20
    static let canvasFeet: CGFloat = 0.80
    /// Visible width of a full bin as a fraction of its height (measured on the renders).
    static let fullBinWidth: CGFloat = 0.62
}

extension BinType {
    /// The asset catalog name of this bin's render.
    var propName: String { "prop-\(rawValue)" }

    /// Height of the object relative to a full-size wheelie bin.
    var propRelativeHeight: CGFloat {
        switch self {
        case .rubbish, .recycling, .gardenWaste, .organics: return 1.0
        case .foodScraps: return 0.59
        case .glass: return 0.38
        case .inorganic: return 0.75
        }
    }

    /// Visible width relative to a full bin's width, for arranging clusters.
    var propRelativeWidth: CGFloat {
        switch self {
        case .rubbish, .recycling, .gardenWaste, .organics: return 1.0
        case .foodScraps: return 0.62
        case .glass: return 0.95
        case .inorganic: return 1.65
        }
    }

    /// Small objects stand in front of the full bins in a cluster.
    var propIsSmall: Bool { propRelativeHeight < 0.9 }
}

// MARK: - A single prop

/// One rendered bin, laid out in a box that runs from the top of a full-size bin to the feet, so
/// `objectHeight` is the height of a full bin at this scale whatever the object. The contact shadow
/// overflows below the box. If the render is missing, a vector bin stands in.
struct BinProp: View {
    let bin: BinType
    var objectHeight: CGFloat

    var body: some View {
        let canvasH = objectHeight / (PropGeometry.canvasFeet - PropGeometry.canvasTop)
        if let image = UIImage(named: bin.propName) {
            let canvasW = canvasH * image.size.width / image.size.height
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: canvasW, height: canvasH)
                .offset(y: -canvasH * PropGeometry.canvasTop)
                .frame(width: canvasW, height: objectHeight, alignment: .top)
                .accessibilityHidden(true)
        } else {
            VectorBin(bin: bin, objectHeight: objectHeight)
                .frame(width: objectHeight * PropGeometry.fullBinWidth, height: objectHeight, alignment: .bottom)
                .accessibilityHidden(true)
        }
    }

    /// Visible width of a full bin at this scale.
    static func fullWidth(_ objectHeight: CGFloat) -> CGFloat { objectHeight * PropGeometry.fullBinWidth }
}

/// The matte-clay trio render from the prototype (recycling, rubbish, food scraps). Measured on
/// the keyed 979 x 1016 canvas: handle top at row 31, feet line at row 963, bins spanning x 53 to 946.
struct TrioProp: View {
    var objectHeight: CGFloat
    static let top: CGFloat = 31.0 / 1016.0
    static let feet: CGFloat = 963.0 / 1016.0
    static let aspect: CGFloat = 979.0 / 1016.0
    /// Visible width relative to the front bin's height.
    static let relativeWidth: CGFloat = (946.0 - 53.0) / (963.0 - 31.0)

    var body: some View {
        let canvasH = objectHeight / (Self.feet - Self.top)
        let canvasW = canvasH * Self.aspect
        Image("prop-trio")
            .resizable()
            .interpolation(.high)
            .frame(width: canvasW, height: canvasH)
            .offset(y: -canvasH * Self.top)
            .frame(width: canvasW, height: objectHeight, alignment: .top)
            .accessibilityHidden(true)
    }
}

// MARK: - Clusters

/// Where each bin stands in a group, in units of a full bin's height (y, scale) and width (x).
struct PropPlacement: Identifiable {
    let bin: BinType
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    var id: BinType { bin }
}

/// A group of bins standing together on one baseline: full bins in a row that recedes to the
/// right, small bins in front, like the household's set at the kerb. Draws the prototype's trio
/// render for Auckland's recycling week, because a true render beats a composite.
struct BinCluster: View {
    let bins: [BinType]
    var objectHeight: CGFloat
    /// Use the composite even for the trio (the street strip's tiny clusters).
    var preferComposite = false

    static let trio: Set<BinType> = [.recycling, .rubbish, .foodScraps]

    var body: some View {
        if !preferComposite, Set(bins) == Self.trio, UIImage(named: "prop-trio") != nil {
            TrioProp(objectHeight: objectHeight)
        } else {
            let placements = Self.arrange(bins)
            let w = BinProp.fullWidth(objectHeight)
            let bounds = Self.bounds(of: placements)
            ZStack(alignment: .bottom) {
                ForEach(placements) { p in
                    BinProp(bin: p.bin, objectHeight: objectHeight * p.scale)
                        .offset(x: (p.x - bounds.midX) * w, y: p.y * objectHeight)
                }
            }
            .frame(width: bounds.width * w, height: objectHeight, alignment: .bottom)
        }
    }

    /// The bins as they stand left to right, so captions and sentences follow the picture.
    static func displayOrder(_ bins: [BinType]) -> [BinType] {
        if Set(bins) == trio { return [.recycling, .rubbish, .foodScraps] }
        return arrange(bins).sorted { $0.x < $1.x }.map(\.bin)
    }

    /// Visible width of the group relative to a full bin's height.
    static func relativeWidth(of bins: [BinType], composite: Bool = false) -> CGFloat {
        if !composite, Set(bins) == trio { return TrioProp.relativeWidth }
        return bounds(of: arrange(bins)).width * PropGeometry.fullBinWidth
    }

    /// Draw order is back to front: the rightmost full bin first, then leftwards, then the small ones.
    static func arrange(_ bins: [BinType]) -> [PropPlacement] {
        let fulls = bins.filter { !$0.propIsSmall }
        let smalls = bins.filter(\.propIsSmall)
        var out: [PropPlacement] = []
        let n = fulls.count
        if Set(bins) == trio {
            // the trio's own arrangement: recycling front left, rubbish behind right, food front right
            return [PropPlacement(bin: .rubbish, x: 0.38, y: -0.07, scale: 0.93),
                    PropPlacement(bin: .recycling, x: -0.30, y: 0, scale: 1),
                    PropPlacement(bin: .foodScraps, x: 0.52, y: 0.03, scale: 1)]
        }
        for (i, bin) in fulls.enumerated().reversed() {
            let x = (CGFloat(i) - CGFloat(n - 1) / 2) * 0.58
            out.append(PropPlacement(bin: bin, x: x, y: -0.045 * CGFloat(i), scale: 1 - 0.035 * CGFloat(i)))
        }
        var sx: CGFloat
        if n == 0 {
            sx = -CGFloat(smalls.count - 1) / 2 * 0.70
        } else if n == 1 {
            // a lone full bin steps left to make room, as in the rubbish-and-food pair
            out = [PropPlacement(bin: fulls[0], x: -0.16, y: -0.04, scale: 0.96)]
            sx = 0.40
        } else {
            sx = (CGFloat(n - 1) / 2) * 0.58 + 0.14
        }
        for bin in smalls {
            out.append(PropPlacement(bin: bin, x: sx, y: 0.02, scale: 1))
            sx += bin == .glass ? 0.80 : 0.62
        }
        return out
    }

    /// Horizontal extent of a set of placements in full-bin widths.
    static func bounds(of placements: [PropPlacement]) -> (minX: CGFloat, maxX: CGFloat, midX: CGFloat, width: CGFloat) {
        var lo = CGFloat.greatestFiniteMagnitude, hi = -CGFloat.greatestFiniteMagnitude
        for p in placements {
            let half = p.bin.propRelativeWidth * p.scale / 2
            lo = min(lo, p.x - half); hi = max(hi, p.x + half)
        }
        if placements.isEmpty { return (0, 0, 0, 0) }
        return (lo, hi, (lo + hi) / 2, hi - lo)
    }
}

// MARK: - Fallback

/// A bin drawn from shapes, in the lid colour, for when a render is missing.
struct VectorBin: View {
    let bin: BinType
    var objectHeight: CGFloat

    var body: some View {
        let h = objectHeight * bin.propRelativeHeight
        let w = objectHeight * PropGeometry.fullBinWidth * min(1, bin.propRelativeWidth)
        Canvas { context, size in
            let body = CGRect(x: size.width / 2 - w * 0.42, y: size.height - h * 0.86, width: w * 0.84, height: h * 0.80)
            var trapezoid = Path()
            trapezoid.move(to: CGPoint(x: body.minX, y: body.minY))
            trapezoid.addLine(to: CGPoint(x: body.maxX, y: body.minY))
            trapezoid.addLine(to: CGPoint(x: body.maxX - w * 0.07, y: body.maxY))
            trapezoid.addLine(to: CGPoint(x: body.minX + w * 0.07, y: body.maxY))
            trapezoid.closeSubpath()
            context.fill(trapezoid, with: .color(Color(hex: 0x4A4036)))
            let lid = CGRect(x: body.minX - w * 0.04, y: body.minY - h * 0.08, width: body.width + w * 0.08, height: h * 0.10)
            context.fill(Path(roundedRect: lid, cornerRadius: h * 0.03), with: .color(bin.lidTone))
            let wheel = CGRect(x: body.maxX - w * 0.26, y: size.height - h * 0.14, width: h * 0.14, height: h * 0.14)
            context.fill(Path(ellipseIn: wheel), with: .color(Color(hex: 0x1E1A16)))
            let shadow = CGRect(x: body.minX, y: size.height - h * 0.04, width: body.width, height: h * 0.06)
            context.fill(Path(ellipseIn: shadow), with: .color(Palette.shadow.opacity(0.12)))
        }
    }
}
