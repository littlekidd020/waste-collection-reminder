import SwiftUI
import CoreMotion

// MARK: - Geometry of the hang tag

enum TagGeometry {
    static let size = CGSize(width: 296, height: 372)
    static let radius: CGFloat = 40
    static let eyeletY: CGFloat = 16          // eyelet centre, from the tag's top edge
    static let eyeletSize: CGFloat = 10
    static var anchor: UnitPoint { UnitPoint(x: 0.5, y: eyeletY / size.height) }
    static let restAngle: Double = -3
}

// MARK: - Motion: the tag is a damped pendulum

/// Listens for a nudge of the phone (CoreMotion user acceleration) and reports a kick in degrees.
@Observable
final class NudgeListener {
    var kick: Double = 0
    var kickID = 0
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let a = motion?.userAcceleration else { return }
            if abs(a.x) > 0.22 {
                self.kick = max(-14, min(14, -a.x * 30))
                self.kickID += 1
            }
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}

// MARK: - Today

struct TodayView: View {
    /// When set, the tag is frozen mid-swing at this angle (the `.extra` capture).
    var frozenSwing: Double? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle: Double = TagGeometry.restAngle
    @State private var drop: CGFloat = 0
    @State private var tagOpacity: Double = 1
    @State private var spheresIn = true
    @State private var copyIn = true
    @State private var dragging = false
    @State private var idleTask: Task<Void, Never>?
    @State private var nudge = NudgeListener()
    @State private var reminderOn = false

    private let collection = Sample.next

    private var swingOffset: Double { abs(angle - TagGeometry.restAngle) }

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            Wash(bins: collection.bins)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    GlassCornerButton(symbol: "gearshape", label: "Settings")
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)

                hangingTag
                    .frame(maxWidth: .infinity)
                    .padding(.top, 96 - 48 - TagGeometry.eyeletY)

                copy
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .opacity(copyIn ? 1 : 0)
                    .offset(y: copyIn ? 0 : 12)

                Spacer(minLength: 0)
            }
        }
        .onAppear(perform: enter)
        .onDisappear { idleTask?.cancel(); nudge.stop() }
        .onChange(of: nudge.kickID) { _, _ in
            guard frozenSwing == nil, !reduceMotion, !dragging else { return }
            swing(to: TagGeometry.restAngle + nudge.kick, velocity: 0)
        }
    }

    // MARK: The tag on its cord

    private var hangingTag: some View {
        let shadowX = 8 + swingOffset * 0.7
        let shadowY = 18 + swingOffset * 0.9
        let shadowBlur = 28 + swingOffset * 1.4
        let shadowOpacity = max(0.08, 0.14 - swingOffset * 0.004)

        let tagShape = RoundedRectangle(cornerRadius: TagGeometry.radius)
        let rotated = RotatedShape(shape: tagShape, angle: .degrees(angle), anchor: TagGeometry.anchor)

        // Liquid Glass inflates when its view is put through rotationEffect, so the glass stays axis-aligned
        // and takes a rotated shape instead; only the printed face and the eyelet rotate as views.
        return ZStack {
            GlassEffectContainer {
                Color.clear
                    .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
                    .glassEffect(.regular, in: rotated)
            }
            ZStack(alignment: .top) {
                TagFace(collection: collection, spheresIn: spheresIn)
                    .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
                tagShape.strokeBorder(.white.opacity(0.35), lineWidth: 1)
                Eyelet(size: TagGeometry.eyeletSize)
                    .offset(y: TagGeometry.eyeletY - TagGeometry.eyeletSize / 2)
            }
            .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
            .rotationEffect(.degrees(angle), anchor: TagGeometry.anchor)
        }
        .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
        .contentShape(.rect)
        .gesture(swingGesture)
        .background(alignment: .top) {
            // Long soft shadow, knocked out under the glass so the glass stays clear.
            RoundedRectangle(cornerRadius: TagGeometry.radius)
                .fill(Palette.shadow.opacity(shadowOpacity))
                .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
                .rotationEffect(.degrees(angle), anchor: TagGeometry.anchor)
                .offset(x: shadowX, y: shadowY)
                .blur(radius: shadowBlur / 2)
                .mask {
                    ZStack {
                        Rectangle().padding(-240)
                        RoundedRectangle(cornerRadius: TagGeometry.radius)
                            .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
                            .rotationEffect(.degrees(angle), anchor: TagGeometry.anchor)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                }
                .allowsHitTesting(false)
        }
        .background(alignment: .top) {
            // The cord: from beyond the top of the screen to the top of the eyelet ring. It does not rotate,
            // because the tag pivots on the eyelet centre, so the ring's top stays where the cord meets it.
            Rectangle()
                .fill(Palette.line)
                .frame(width: 1.5, height: 900)
                .offset(y: -900 + TagGeometry.eyeletY - TagGeometry.eyeletSize / 2 + 0.75)
                .frame(width: 1.5, height: 0, alignment: .top)
                .allowsHitTesting(false)
        }
        .frame(width: TagGeometry.size.width, height: TagGeometry.size.height)
        .offset(y: drop)
        .opacity(tagOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Sample.relative(collection.date)), \(Sample.weekday(collection.date)) \(Sample.dayNumber(collection.date)) \(Sample.monthName(collection.date)), Mount Eden. \(Sample.list(collection.bins)).")
    }

    private var swingGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard frozenSwing == nil else { return }
                dragging = true
                idleTask?.cancel()
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) {
                    angle = TagGeometry.restAngle - max(-22, min(22, Double(value.translation.width) * 0.09))
                }
            }
            .onEnded { value in
                guard frozenSwing == nil else { return }
                dragging = false
                swing(to: angle, velocity: -Double(value.velocity.width) * 0.09)
            }
    }

    // MARK: Copy below the tag

    private var copy: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(Sample.list(collection.bins)) go out tonight.")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Put them out by \(Sample.putOutBy)")
                .font(.system(size: 17))
                .monospacedDigit()
                .foregroundStyle(Palette.muted)
                .padding(.top, 8)
            Button {
                reminderOn.toggle()
            } label: {
                Text(reminderOn ? "Reminder set for 7 pm" : "Remind me at 7 pm")
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .tint(Palette.accent)
            .controlSize(.large)
            .padding(.top, 24)
            TagLabel("Next Tuesday · no recycling")
                .padding(.top, 24)
        }
    }

    // MARK: Motion

    private func enter() {
        nudge.start()
        if let frozen = frozenSwing {
            angle = frozen
            return
        }
        if reduceMotion {
            angle = TagGeometry.restAngle
            tagOpacity = 0
            withAnimation(.easeOut(duration: 0.4)) { tagOpacity = 1 }
            return
        }
        // Drop from above on the cord, released at an angle, then swing to rest as a damped pendulum.
        drop = -560
        angle = 16
        spheresIn = false
        copyIn = false
        withAnimation(.spring(response: 0.7, dampingFraction: 0.78).delay(0.1)) { drop = 0 }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.6).delay(0.1)) { angle = TagGeometry.restAngle }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.7)) { spheresIn = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.9)) { copyIn = true }
        startIdle(after: 2.4)
    }

    /// Release the tag from `from` with an angular velocity; the spring is the damped pendulum.
    private func swing(to from: Double, velocity: Double) {
        idleTask?.cancel()
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { angle = from }
        let delta = from - TagGeometry.restAngle
        let v = delta == 0 ? 0 : velocity / -delta
        withAnimation(.interpolatingSpring(duration: 0.9, bounce: 0.4, initialVelocity: v)) {
            angle = TagGeometry.restAngle
        }
        startIdle(after: 2.2)
    }

    /// A barely visible sway, 0.6 degrees over eight seconds, like air moving past the bin.
    private func startIdle(after delay: Double) {
        guard !reduceMotion else { return }
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                angle = TagGeometry.restAngle + 0.6
            }
        }
    }
}

// MARK: - The face of the tag

struct TagFace: View {
    let collection: Sample.Collection
    var spheresIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                TagLabel("\(Sample.relative(collection.date)) · \(Sample.weekday(collection.date, short: true))")
                Spacer(minLength: 16)
                TagLabel("Mount Eden")
            }

            Spacer(minLength: 0)

            Text(Sample.dayNumber(collection.date))
                .font(.system(size: 176, weight: .regular, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.leading, -8)          // optical: pull the serif's side bearing onto the label edge
                .frame(height: 150, alignment: .center)
                .contentTransition(.numericText())
            Text(Sample.monthName(collection.date))
                .font(.system(size: 17))
                .foregroundStyle(Palette.muted)

            Spacer(minLength: 0)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(collection.bins.enumerated()), id: \.element) { i, bin in
                    VStack(alignment: .center, spacing: 10) {
                        LidSphere(bin: bin, size: 30)
                            .offset(y: spheresIn ? 0 : -14)
                            .opacity(spheresIn ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(Double(i) * 0.04), value: spheresIn)
                        TagLabel(bin.name.replacingOccurrences(of: " ", with: "\n"), size: 11)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .padding(28)
    }
}

// MARK: - The wash behind the glass

/// Three large blurred radial gradients of the due bins' tints, in the upper half, so the glass has light to refract.
struct Wash: View {
    let bins: [Bin]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                blob(.recycling, d: 640)
                    .position(x: w * 0.12 + (drift ? 18 : -10), y: 170 + (drift ? 12 : -8))
                blob(.rubbish, d: 640)
                    .position(x: w * 0.92 + (drift ? -16 : 10), y: 230 + (drift ? -10 : 10))
                blob(.foodScraps, d: 600)
                    .position(x: w * 0.42 + (drift ? 12 : -14), y: 380 + (drift ? 8 : -6))
            }
            .frame(width: w, height: geo.size.height, alignment: .top)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func blob(_ bin: Bin, d: CGFloat) -> some View {
        let color = bins.contains(bin) ? bin.lid : Palette.surface
        return Circle()
            .fill(RadialGradient(colors: [color, color.opacity(0)], center: .center, startRadius: 0, endRadius: d / 2))
            .frame(width: d, height: d)
            .blur(radius: 40)
            .opacity(WashTuning.opacity)
    }
}

enum WashTuning {
    static let opacity: Double = 0.55
}
