import SwiftUI

struct ScheduleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: Date = Sample.next.date
    @State private var appeared = false

    private let collections = Sample.collections
    private let railY: CGFloat = 58            // about 120 pt from the top of the screen, under the 62 pt safe area

    private var selection: Sample.Collection {
        collections.first { $0.date == selected } ?? Sample.next
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    rail
                    detail
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            HStack {
                Spacer()
                GlassCornerButton(symbol: "calendar.badge.clock", label: "Add collections to Calendar")
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            if reduceMotion { appeared = true } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { appeared = true }
            }
        }
    }

    // MARK: The rail with tags hanging from it

    private var rail: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Array(collections.enumerated()), id: \.element.id) { i, c in
                        HangingDayTag(collection: c,
                                      isSelected: c.date == selected,
                                      tilt: [-2.0, 1.5, -1.0, 2.0, -1.5, 1.0, -2.0, 1.5][i % 8])
                            .offset(y: appeared ? 0 : -24)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85).delay(Double(i) * 0.04), value: appeared)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { selected = c.date }
                            }
                    }
                }
                .padding(.top, railY)
                .background(alignment: .topLeading) {
                    // The rail starts at the first tag's leading edge and runs past the last one.
                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1.5)
                        .padding(.trailing, -48)
                        .offset(y: railY - 0.75)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    // MARK: The selected collection written out

    private var detail: some View {
        let c = selection
        let next = collections.first { $0.date > c.date }
        return VStack(alignment: .leading, spacing: 0) {
            TagLabel("\(Sample.weekday(c.date)) \(Sample.dayNumber(c.date)) \(Sample.monthName(c.date))")
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.bottom, 16)

            ForEach(Array(c.bins.enumerated()), id: \.element) { i, bin in
                if i > 0 { Rectangle().fill(Palette.line).frame(height: 1) }
                HStack(spacing: 16) {
                    LidSphere(bin: bin, size: 18)
                    Text(bin.name)
                        .font(.system(size: 24))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    TagLabel(bin.frequency)
                }
                .frame(minHeight: 64)
                .accessibilityElement(children: .combine)
            }

            if let next {
                Text("The week after, \(Sample.weekday(next.date)) \(Sample.dayNumber(next.date)) \(Sample.monthName(next.date)): \(Sample.list(next.bins).lowercased()).")
                    .font(.system(size: 15))
                    .monospacedDigit()
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "snowflake")
                    .font(.system(size: 15))
                    .accessibilityHidden(true)
                Text(Sample.holidayNotice)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 15))
            .foregroundStyle(Palette.muted)
            .padding(.top, 16)
        }
    }
}

/// One small tag on the rail: paper for the others, glass for the selected collection.
struct HangingDayTag: View {
    let collection: Sample.Collection
    let isSelected: Bool
    let tilt: Double

    private var size: CGSize { isSelected ? CGSize(width: 84, height: 122) : CGSize(width: 72, height: 104) }
    private var cord: CGFloat { isSelected ? 22 : 12 }
    private let eyeletY: CGFloat = 11
    private let eyeletSize: CGFloat = 6
    private var radius: CGFloat { isSelected ? 22 : 18 }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.line)
                .frame(width: 1.5, height: cord + eyeletY - eyeletSize / 2)
                .padding(.bottom, -(eyeletY - eyeletSize / 2))
                .zIndex(1)
            face
                .rotationEffect(.degrees(isSelected ? 0 : tilt), anchor: UnitPoint(x: 0.5, y: eyeletY / size.height))
        }
        .frame(width: size.width)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Sample.weekday(collection.date)) \(Sample.dayNumber(collection.date)) \(Sample.monthName(collection.date)): \(Sample.list(collection.bins))")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private var face: some View {
        let content = VStack(spacing: 0) {
            TagLabel(Sample.weekday(collection.date, short: true))
                .padding(.top, eyeletY + eyeletSize / 2 + 8)
            Spacer(minLength: 0)
            Text(Sample.dayNumber(collection.date))
                .font(.system(size: 30, weight: .regular, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                ForEach(collection.bins) { LidSphere(bin: $0, size: 9) }
            }
            .padding(.bottom, 14)
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .top) {
            Eyelet(size: eyeletSize, lineWidth: 1.2)
                .offset(y: eyeletY - eyeletSize / 2)
        }

        if isSelected {
            GlassEffectContainer {
                content
                    .glassEffect(.regular, in: .rect(cornerRadius: radius))
                    .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(.white.opacity(0.35), lineWidth: 1))
            }
            .background {
                // Light for the glass to bend: the selected bins' colours, blurred behind the tag.
                ZStack {
                    ForEach(Array(collection.bins.enumerated()), id: \.element) { i, bin in
                        Circle()
                            .fill(bin.lid.opacity(0.45))
                            .frame(width: 70, height: 70)
                            .offset(x: [-22.0, 24.0, -4.0][i % 3], y: [-24.0, -4.0, 30.0][i % 3])
                    }
                }
                .blur(radius: 22)
            }
            .shadow(color: Palette.shadow.opacity(0.12), radius: 14, x: 4, y: 10)
        } else {
            content
                .background(Palette.surface, in: .rect(cornerRadius: radius))
                .shadow(color: Palette.shadow.opacity(0.08), radius: 6, x: 2, y: 4)
        }
    }
}
