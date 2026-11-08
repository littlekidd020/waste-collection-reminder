import SwiftUI

/// Today: tomorrow's three bins stand on the linen floor. Swipe them right and they roll to the kerb.
struct TodayView: View {
    /// For the `.extra` capture: show the settled "at the kerb" state with no entrance.
    var frozenAtKerb = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var atKerb = false
    @State private var binsIn = false
    @State private var captionsIn = false
    @State private var verdictIn = false
    @State private var dragX: CGFloat = 0
    @State private var tilt: Double = -5
    @State private var reminderSet = false

    private let next = Sample.next
    private let trioWidth: CGFloat = 300
    private let trioFeet: CGFloat = 1359.0 / 1536.0   // feet line inside the trio render
    private let kerbShift: CGFloat = 54

    private var eyebrow: String {
        "\(Sample.relative(next.date)) · \(Sample.weekday(next.date)) \(Sample.dayNumber(next.date)) \(Sample.monthName(next.date))"
    }

    var body: some View {
        ZStack {
            stage
            foreground
        }
        .sensoryFeedback(.success, trigger: atKerb)
        .onAppear(perform: enter)
    }

    // MARK: Stage: ground, band, the bins

    private var stage: some View {
        GeometryReader { geo in
            let W = geo.size.width, H = geo.size.height
            let feetY = (H * 0.68).rounded()
            let trioH = trioWidth * 1.5
            ZStack(alignment: .topLeading) {
                Palette.ground
                VStack(spacing: 0) {
                    Color.clear.frame(height: feetY - 59)
                    GroundBand().frame(height: 120)
                    Palette.surface
                }
                Grain(opacity: 0.05)

                // a very soft, wide grounding shadow under the group
                Ellipse()
                    .fill(Palette.shadow.opacity(0.06))
                    .frame(width: 280, height: 32)
                    .blur(radius: 14)
                    .position(x: W / 2 + 6 + xShift, y: feetY + 6)

                Image("bins-trio")
                    .resizable()
                    .scaledToFit()
                    .frame(width: trioWidth, height: trioH)
                    .rotationEffect(.degrees(binsIn ? tilt : -5), anchor: UnitPoint(x: 0.5, y: trioFeet))
                    .position(x: W / 2 + xShift + (binsIn ? 0 : W),
                              y: feetY - trioH * trioFeet + trioH / 2)
                    .opacity(reduceMotion && !binsIn ? 0 : 1)
                    .accessibilityLabel("Recycling, rubbish and food scraps bins")
                    .accessibilityHint(atKerb ? "" : "Swipe right when they are out")
                    .contentShape(Rectangle().inset(by: 60))
                    .gesture(rollGesture)

                HStack(spacing: 24) {
                    ForEach(next.bins) { BinCaption(bin: $0) }
                }
                .opacity(captionsIn ? 1 : 0)
                .offset(y: captionsIn ? 0 : 6)
                .position(x: W / 2, y: feetY + 30)

                // quiet awareness of the fortnight rhythm
                Text("Next Tuesday: rubbish and food scraps only.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
                    .opacity(captionsIn ? 1 : 0)
                    .position(x: W / 2, y: feetY + 66)
            }
        }
        .ignoresSafeArea()
    }

    private var xShift: CGFloat { (atKerb ? kerbShift : 0) + dragX }

    // MARK: Foreground: chrome, verdict, action

    private var foreground: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.bottom, 32)

            Text(eyebrow)
                .kerbLabel()
                .monospacedDigit()
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text(atKerb ? "Done for tonight" : "Out tonight")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.interpolate)
                Text(atKerb
                     ? "They are at the kerb. Collection is from 7 am."
                     : "\(Sample.list(next.bins)). Put them out by \(Sample.putOutBy).")
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            .opacity(verdictIn ? 1 : 0)
            .offset(y: verdictIn ? 0 : 12)

            Spacer(minLength: 0)
                .allowsHitTesting(false)

            primaryAction
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var topBar: some View {
        GlassEffectContainer(spacing: 12) {
            ZStack {
                Button {} label: {
                    HStack(spacing: 6) {
                        Text("Mount Eden")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .accessibilityLabel("Location, Mount Eden. Change address")

                HStack {
                    Spacer()
                    GlassCircleButton(systemImage: "gearshape", label: "Settings")
                }
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if atKerb {
            Button { roll(toKerb: false) } label: {
                Text("Undo")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .accessibilityHint("Bring the bins back in")
        } else {
            Button {
                withAnimation(.snappy) { reminderSet.toggle() }
            } label: {
                Text(reminderSet ? "Reminder set for 7 pm" : "Remind me at 7 pm")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 8)
                    .contentTransition(.interpolate)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Palette.accent)
            .opacity(verdictIn ? 1 : 0)
        }
    }

    // MARK: Motion

    private func enter() {
        if frozenAtKerb {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                atKerb = true; binsIn = true; captionsIn = true; verdictIn = true; tilt = 0
            }
            return
        }
        guard !binsIn else { return }
        if reduceMotion {
            tilt = 0
            withAnimation(.easeOut(duration: 0.35)) { binsIn = true; captionsIn = true; verdictIn = true }
            return
        }
        // the bins roll in from the right, leaning on their wheels, then stand upright
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { binsIn = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.38)) { tilt = 0 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.08)) { verdictIn = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.70 + 0.08)) { captionsIn = true }
    }

    private var rollGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                let dx = v.translation.width
                if atKerb {
                    dragX = min(0, dx) * 0.5
                    tilt = max(-4, Double(dragX) / 12)
                } else {
                    dragX = max(0, dx) * 0.5
                    tilt = min(4, Double(dragX) / 12)
                }
            }
            .onEnded { v in
                let dx = v.predictedEndTranslation.width
                if !atKerb && dx > 120 { roll(toKerb: true) }
                else if atKerb && dx < -120 { roll(toKerb: false) }
                else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { dragX = 0; tilt = 0 }
                }
            }
    }

    private func roll(toKerb: Bool) {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) { atKerb = toKerb; dragX = 0; tilt = 0 }
            return
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            atKerb = toKerb; dragX = 0; tilt = toKerb ? 4 : -4
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.32)) { tilt = 0 }
    }
}
