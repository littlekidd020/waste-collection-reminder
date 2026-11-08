import SwiftUI

struct TodayDialView: View {
    /// When set, the dial is frozen mid-scrub on this day (the `.extra` capture).
    var frozenScrubDay: Int?
    @State private var scrubDay: Int?

    init(frozenScrubDay: Int? = nil) {
        self.frozenScrubDay = frozenScrubDay
        _scrubDay = State(initialValue: frozenScrubDay)
    }

    private var target: Sample.Collection {
        guard let d = scrubDay else { return Sample.next }
        return Fortnight.collection(onOrAfterDay: d)
    }
    private var days: Int { Fortnight.daysFromToday(target.date) }
    private var eyebrow: String { days == 1 ? "Tomorrow" : days == 0 ? "Today" : "In \(days) days" }

    private var sentence: String {
        Sample.list(target.bins) + (days == 1 ? " go out tonight." : " go out.")
    }
    private var reminder: String {
        days == 1 ? "Remind me at 7 pm" : "Remind me \(Fortnight.shortDate(Fortnight.calendar.date(byAdding: .day, value: -1, to: target.date)!)) at 7 pm"
    }

    var body: some View {
        GeometryReader { geo in
            let full = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let centreY = full * 0.38 - geo.safeAreaInsets.top
            ZStack(alignment: .topLeading) {
                // Hero
                ZStack {
                    FortnightDial(scrubDay: $scrubDay, target: target, allowsScrub: frozenScrubDay == nil) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.6)) { scrubDay = nil }
                    }
                    centre
                }
                .position(x: geo.size.width / 2, y: centreY)

                // Verdict
                VStack(alignment: .leading, spacing: 8) {
                    Text(sentence)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                    Text("Put them out by \(Sample.putOutBy)")
                        .font(.system(size: 17))
                        .foregroundStyle(Palette.muted)
                    Button {} label: {
                        Text(reminder)
                            .font(.system(size: 17, weight: .semibold))
                            .contentTransition(.numericText())
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Palette.accent)
                    .controlSize(.large)
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .frame(width: geo.size.width, alignment: .leading)
                .offset(y: centreY + FortnightDial.frameSize / 2 + 16)
                .animation(.easeInOut(duration: 0.25), value: target)

                header
            }
        }
        .background(LinenGround())
    }

    private var centre: some View {
        VStack(spacing: 2) {
            Eyebrow(eyebrow)
                .contentTransition(.numericText())
            Text(Fortnight.shortDate(target.date))
                .font(.system(size: 60, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text("\(target.bins.count) bins")
                .font(.system(size: 15))
                .monospacedDigit()
                .foregroundStyle(Palette.muted)
                .contentTransition(.numericText())
        }
        .frame(width: 200)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: target)
        .allowsHitTesting(false)
    }

    private var header: some View {
        GlassEffectContainer(spacing: 12) {
            ZStack {
                Button {} label: {
                    HStack(spacing: 6) {
                        Text("Mount Eden").font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 6)
                    .frame(height: 32)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .accessibilityLabel("Location, Mount Eden")

                HStack {
                    Spacer()
                    Button {} label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Settings")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
