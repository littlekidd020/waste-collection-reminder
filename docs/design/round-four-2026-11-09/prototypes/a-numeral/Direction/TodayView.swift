import SwiftUI

struct TodayView: View {
    let showReminderSheet: Bool
    @State private var shown = false
    @State private var sheet = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    private let next = Sample.next
    private let margin: CGFloat = 24

    var body: some View {
        ZStack {
            LinenGround()
            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.top, 4)

                Text("Tomorrow · \(Sample.weekday(next.date))")
                    .eyebrow(13)
                    .padding(.top, 32)
                    .settle(shown, delay: 0, reduce: reduce, from: 12)

                hero
                    .padding(.top, 2)
                    .settle(shown, delay: 0.02, reduce: reduce)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Sample.list(next.bins)) go out tonight.")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Put them out by \(Sample.putOutBy)")
                        .font(.system(size: 17, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(Palette.muted)
                }
                .padding(.top, 24)
                .padding(.trailing, 24)
                .settle(shown, delay: 0.08, reduce: reduce)

                bins
                    .padding(.top, 32)

                Button { sheet = true } label: {
                    Text("Remind me at 7 pm")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .padding(.top, 32)
                .settle(shown, delay: 0.28, reduce: reduce)

                Spacer(minLength: 24)

                FortnightStrip(shown: shown, reduce: reduce)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, margin)
        }
        .onAppear {
            shown = true
            if showReminderSheet {
                Task { try? await Task.sleep(for: .seconds(0.6)); sheet = true }
            }
        }
        .sheet(isPresented: $sheet) {
            ReminderSheet()
                .presentationDetents([.fraction(0.42)])
                .presentationBackground(.thinMaterial)
                .presentationDragIndicator(.visible)
        }
    }

    private var topBar: some View {
        GlassEffectContainer(spacing: 12) {
            ZStack {
                Button {} label: {
                    HStack(spacing: 6) {
                        Text("Mount Eden")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
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
                    GlassCircleButton(symbol: "gearshape", label: "Settings")
                }
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(Sample.dayNumber(next.date))
                .font(.system(size: 180, weight: .light))
                .tracking(-8)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                // Optical alignment: pull the "1" side bearing back to the 24 pt margin
                // and trim the empty line-box above the cap height.
                .padding(.leading, -21)
                .padding(.top, -34)
                .padding(.bottom, -36)
            Text(Sample.monthName(next.date))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tuesday 10 November")
    }

    private var bins: some View {
        HStack(alignment: .top, spacing: 28) {
            ForEach(Array(next.bins.enumerated()), id: \.element) { i, bin in
                VStack(alignment: .leading, spacing: 12) {
                    LidSphere(bin: bin, size: 36)
                        .modifier(DropIn(shown: shown, delay: 0.16 + Double(i) * 0.04, reduce: reduce))
                    Text(bin.name)
                        .eyebrow()
                        .fixedSize()
                        .settle(shown, delay: 0.2 + Double(i) * 0.04, reduce: reduce, from: 8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(bin.name)
            }
        }
    }
}

/// The fortnight as two rows of seven spheres, echoing the app icon.
struct FortnightStrip: View {
    let shown: Bool
    let reduce: Bool
    @State private var breathe = false

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            row(label: "This week", raisedBin: .recycling, isThisWeek: true)
            row(label: "Next week", raisedBin: .foodScraps, isThisWeek: false)
        }
        .opacity(shown ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: shown)
        .onAppear {
            guard !reduce else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1.2)) { breathe = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("This week: recycling, rubbish and food scraps on Tuesday. Next week: rubbish and food scraps on Tuesday.")
    }

    private func row(label: String, raisedBin: Bin, isThisWeek: Bool) -> some View {
        GridRow {
            Text(label)
                .eyebrow(12)
                .fixedSize()
                .gridColumnAlignment(.leading)
            HStack(spacing: 9) {
                ForEach(0..<7, id: \.self) { d in
                    if d == 1 {
                        LidSphere(bin: raisedBin, size: 12, raised: true)
                            .scaleEffect(isThisWeek && breathe ? 1.06 : 1)
                            .offset(y: isThisWeek && breathe ? -0.8 : 0)
                    } else {
                        LidSphere(bin: nil, size: 12)
                            .opacity(isThisWeek && d == 0 ? 1 : 0.95)
                    }
                }
            }
        }
    }
}
