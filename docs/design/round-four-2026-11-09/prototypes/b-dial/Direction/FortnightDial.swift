import SwiftUI

/// The hero: a matte clay ring divided into fourteen days, bins sitting on it as spheres, a needle at now.
/// The ring runs clockwise from now at twelve o'clock.
struct FortnightDial: View {
    /// Day the needle has been dragged to, or nil when it rests at now.
    @Binding var scrubDay: Int?
    var target: Sample.Collection
    var allowsScrub: Bool = true
    var onRelease: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Entrance state
    @State private var draw: CGFloat = 0
    @State private var ringOpacity: Double = 0
    @State private var ticksOn = false
    @State private var landed = false
    @State private var settle: Double = -48
    @State private var launch = Date()

    static let outer: CGFloat = 312
    static let tube: CGFloat = 28
    static let frameSize: CGFloat = 372
    private var rMid: CGFloat { (Self.outer - Self.tube) / 2 }   // 142
    private var rIn: CGFloat { Self.outer / 2 - Self.tube }      // 128
    private var rOut: CGFloat { Self.outer / 2 }                 // 156
    private var rLabel: CGFloat { rOut + 16 }
    private var c: CGPoint { CGPoint(x: Self.frameSize / 2, y: Self.frameSize / 2) }

    private var sweepEnd: Double { min(360, Fortnight.angle(for: Fortnight.putOutTime(target))) }
    private var needleBase: Double { scrubDay.map { $0 == 0 ? 0 : Fortnight.dayCentre($0) } ?? 0 }

    /// Bins placed on the ring: the first sits at 7 am on its Tuesday, the rest fan forward along the day.
    private struct Placed: Identifiable { let id: String; let bin: Bin; let angle: Double; let collection: Int; let order: Int }
    private var placed: [Placed] {
        var out: [Placed] = []
        let step = 7.4
        var order = 0
        for (ci, col) in Sample.collections.prefix(2).enumerated() {
            let start = Fortnight.angle(for: Fortnight.putOutTime(col))
            for (bi, bin) in col.bins.enumerated() {
                out.append(Placed(id: "\(ci)-\(bin.rawValue)", bin: bin, angle: start + Double(bi) * step, collection: ci, order: order))
                order += 1
            }
        }
        return out
    }
    private var targetIndex: Int { Sample.collections.firstIndex(of: target) ?? 0 }

    var body: some View {
        ZStack {
            TorusRing(outer: Self.outer, tube: Self.tube, draw: draw,
                      fill: (Palette.accent.opacity(0.28), CGFloat(sweepEnd / 360), false))
                .opacity(ringOpacity)
                .animation(.spring(response: 0.5, dampingFraction: 0.9), value: sweepEnd)

            ticks.opacity(ticksOn ? 1 : 0)
            labels.opacity(ticksOn ? 1 : 0)

            ForEach(placed.sorted { $0.order > $1.order }) { p in
                let highlighted = p.collection == targetIndex && scrubDay != nil
                let dimmed = scrubDay != nil && p.collection != targetIndex
                LidSphere(bin: p.bin, size: 22, raised: highlighted)
                    .scaleEffect(highlighted ? 1.14 : 1)
                    .opacity(dimmed ? 0.45 : 1)
                    .position(Fortnight.point(p.angle, radius: rMid, centre: c))
                    .offset(y: landed ? 0 : -26)
                    .opacity(landed ? 1 : 0)
                    .animation(reduceMotion ? .easeOut(duration: 0.3)
                               : .spring(response: 0.42, dampingFraction: 0.52).delay(0.62 + 0.07 * Double(p.order)), value: landed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: highlighted)
            }

            TimelineView(.everyMinute) { context in
                // One minute is 360 / 20 160 of a turn: the needle creeps with real time, imperceptibly.
                let idle = scrubDay == nil ? context.date.timeIntervalSince(launch) / 60 * 360 / (14 * 1440) : 0
                needle(angle: needleBase + settle + idle)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: scrubDay)
        }
        .frame(width: Self.frameSize, height: Self.frameSize)
        .contentShape(Circle())
        .gesture(scrub)
        .sensoryFeedback(.impact(weight: .light), trigger: scrubDay)
        .onAppear(perform: enter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fortnight dial")
        .accessibilityValue("Next collection \(Sample.weekday(target.date)) \(Sample.dayNumber(target.date)), \(Sample.list(target.bins))")
        .accessibilityAdjustableAction { dir in
            let cur = scrubDay ?? 0
            scrubDay = dir == .increment ? min(13, cur + 1) : max(0, cur - 1)
        }
    }

    // MARK: Pieces

    private var ticks: some View {
        Canvas { ctx, _ in
            for k in 0..<Fortnight.days {
                let a = Fortnight.dayStart(k)
                var p = Path()
                p.move(to: Fortnight.point(a, radius: rIn + 3, centre: c))
                p.addLine(to: Fortnight.point(a, radius: rOut - 3, centre: c))
                // Engraved: a dark cut with a lit edge on the side facing the light.
                var lit = Path()
                let off = Fortnight.point(a - 0.32, radius: rIn + 3, centre: c)
                let off2 = Fortnight.point(a - 0.32, radius: rOut - 3, centre: c)
                lit.move(to: off); lit.addLine(to: off2)
                ctx.stroke(lit, with: .color(.white.opacity(0.55)), lineWidth: 0.6)
                ctx.stroke(p, with: .color(Palette.shadow.opacity(0.30)), lineWidth: 0.7)
            }
        }
        .frame(width: Self.frameSize, height: Self.frameSize)
        .allowsHitTesting(false)
    }

    private var labels: some View {
        ForEach(0..<Fortnight.days, id: \.self) { k in
            let d = Fortnight.date(ofDay: k)
            let isTarget = Fortnight.calendar.isDate(d, inSameDayAs: target.date)
            Text(String(Sample.weekday(d, short: true).prefix(1)))
                .font(.system(size: 10, weight: isTarget ? .bold : .semibold))
                .textCase(.uppercase)
                .foregroundStyle(isTarget ? Palette.ink : Palette.muted)
                .position(Fortnight.point(Fortnight.dayCentre(k), radius: rLabel, centre: c))
                .animation(.easeOut(duration: 0.2), value: isTarget)
        }
        .accessibilityHidden(true)
    }

    /// The needle runs from the hub to just past the ring. Where it would cross the centre type
    /// it passes under it: drawn only from the edge of the type block, with the hub as a 6 pt bead there.
    private func needle(angle: Double) -> some View {
        let rad = angle * .pi / 180
        let dx = abs(sin(rad)), dy = abs(cos(rad))
        let hw: Double = 96, hh: Double = 60
        let exit = min(dx > 0.001 ? hw / dx : .infinity, dy > 0.001 ? hh / dy : .infinity)
        let start = CGFloat(exit + 6)
        let tip = rOut + 5
        return ZStack {
            Path { p in
                p.move(to: Fortnight.point(angle, radius: start, centre: c))
                p.addLine(to: Fortnight.point(angle, radius: tip, centre: c))
            }
            .stroke(Palette.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .shadow(color: Palette.shadow.opacity(0.25), radius: 1.5, x: 0.5, y: 1.5)
            Circle()
                .fill(Palette.accent)
                .frame(width: 6, height: 6)
                .shadow(color: Palette.shadow.opacity(0.25), radius: 1.5, x: 0.5, y: 1.5)
                .position(Fortnight.point(angle, radius: start, centre: c))
        }
        .frame(width: Self.frameSize, height: Self.frameSize)
        .allowsHitTesting(false)
    }

    private var scrub: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                guard allowsScrub else { return }
                let dx = Double(v.location.x - c.x), dy = Double(v.location.y - c.y)
                let a = atan2(dx, -dy) * 180 / .pi
                let day = Fortnight.dayIndex(for: a)
                if day != scrubDay { scrubDay = day }
            }
            .onEnded { _ in
                guard allowsScrub else { return }
                onRelease()
            }
    }

    private func enter() {
        launch = Date()
        if reduceMotion {
            draw = 1; settle = 0
            withAnimation(.easeOut(duration: 0.4)) { ringOpacity = 1; ticksOn = true; landed = true }
            return
        }
        ringOpacity = 1
        withAnimation(.timingCurve(0.45, 0, 0.2, 1, duration: 0.7)) { draw = 1 }
        withAnimation(.easeOut(duration: 0.35).delay(0.45)) { ticksOn = true }
        landed = true
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3)) { settle = 0 }
    }
}
