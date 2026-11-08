import SwiftUI

struct GuideView: View {
    @State private var page: Bin = Sample.guideBins[0]
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            TabView(selection: $page) {
                ForEach(Sample.guideBins) { bin in
                    GuidePage(bin: bin, shown: shown, reduce: reduce)
                        .tag(bin)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .center) {
                indicator
                Spacer()
                GlassEffectContainer {
                    GlassCircleButton(symbol: "safari", label: "Open Auckland Council's bin page")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .onAppear { shown = true }
    }

    private var indicator: some View {
        HStack(spacing: 10) {
            ForEach(Sample.guideBins) { b in
                LidSphere(bin: b, size: 8, raised: b == page)
                    .opacity(b == page ? 1 : 0.55)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \((Sample.guideBins.firstIndex(of: page) ?? 0) + 1) of \(Sample.guideBins.count), \(page.name)")
    }
}

struct GuidePage: View {
    let bin: Bin
    let shown: Bool
    let reduce: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(bin.frequency)
                    .eyebrow(13)
                    .padding(.top, 76)
                    .settle(shown, delay: 0, reduce: reduce, from: 12)
                Text(bin.name)
                    .font(.system(size: 44, weight: .regular))
                    .tracking(-0.6)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 2)
                    .settle(shown, delay: 0.04, reduce: reduce)

                LidSphere(bin: bin, size: 184)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                    .modifier(DropIn(shown: shown, delay: 0.1, reduce: reduce))

                Text(Sample.blurb(bin))
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .settle(shown, delay: 0.16, reduce: reduce)

                HStack(alignment: .top, spacing: 20) {
                    column("Yes", Sample.accepted(bin), colour: Palette.ink)
                    Rectangle().fill(Palette.line).frame(width: 0.5)
                    column("No", Sample.refused(bin), colour: Palette.muted)
                }
                .padding(.top, 32)
                .settle(shown, delay: 0.2, reduce: reduce)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private func column(_ title: String, _ items: [String], colour: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).eyebrow(12)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 15))
                    .foregroundStyle(colour)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
