import SwiftUI

/// Guide: one page per bin, the bin itself standing on the floor, what goes in and what stays out.
struct GuideView: View {
    @State private var page: Bin = Sample.guideBins[0]

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            TabView(selection: $page) {
                ForEach(Sample.guideBins) { bin in
                    GuidePage(bin: bin)
                        .tag(bin)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            HStack {
                HStack(spacing: 10) {
                    ForEach(Sample.guideBins) { b in
                        LidSphere(bin: b, size: 8, raised: b == page)
                            .opacity(b == page ? 1 : 0.55)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(page.name), page \((Sample.guideBins.firstIndex(of: page) ?? 0) + 1) of \(Sample.guideBins.count)")
                Spacer()
                GlassEffectContainer {
                    GlassCircleButton(systemImage: "safari", label: "Open the council guide")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

struct GuidePage: View {
    let bin: Bin

    private var heroHeight: CGFloat { 268 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(bin.frequency) · Tuesdays").kerbLabel()
                    .padding(.bottom, 4)
                Text(bin.name)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                hero
                    .padding(.horizontal, -24)

                Text(Sample.blurb(bin))
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)

                HStack(alignment: .top, spacing: 20) {
                    column("Yes", Sample.accepted(bin), color: Palette.ink)
                    Rectangle().fill(Palette.line).frame(width: 1)
                    column("No", Sample.refused(bin), color: Palette.muted)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 68)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            GroundBand(returns: true, peak: 0.62)
                .frame(height: 120)
                .offset(y: 42)
            BinProp(bin: bin, objectHeight: heroHeight)
                .padding(.bottom, 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight + 8, alignment: .bottom)
        .padding(.top, 8)
        .padding(.bottom, 40)
    }

    private func column(_ title: String, _ items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).kerbLabel(12)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
