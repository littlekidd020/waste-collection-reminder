import SwiftUI
import SwiftData

/// Guide: one page per bin the council collects, the bin itself standing on the floor, what goes in
/// and what stays out. Lid spheres at the top leading edge show the page; a glass safari circle opens
/// the council's own guide for the current bin.
struct GuideView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: BinType = .rubbish
    @State private var safariLink: GuideLink?

    private var profile: UserProfile? { profiles.first }
    private var council: Council? { profile.flatMap { DataService.shared.council(for: $0) } }
    private var zone: CollectionZone? { profile.flatMap { DataService.shared.zone(for: $0) } }
    private var bins: [BinType] { BinType.guideBins(for: council) }
    private var current: BinType { bins.contains(page) ? page : (bins.first ?? .rubbish) }

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            TabView(selection: $page) {
                ForEach(bins) { bin in
                    GuidePage(bin: bin, council: council,
                              schedule: zone?.schedules.first { $0.binType == bin },
                              open: { safariLink = GuideLink(url: $0) })
                        .tag(bin)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            topBar
        }
        .onAppear(perform: settlePage)
        .onChange(of: bins) { _, _ in settlePage() }
        .sheet(item: $safariLink) { SafariView(url: $0.url).ignoresSafeArea() }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(alignment: .center) {
            indicator
            Spacer(minLength: 16)
            GlassEffectContainer {
                GlassCircleButton(systemImage: "safari", label: L("Open the council guide")) {
                    safariLink = GuideLink(url: current.guideSourceURL(for: council))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            // a linen scrim so scrolled copy fades out beneath the spheres instead of colliding
            VStack(spacing: 0) {
                ZStack { Palette.ground; Grain() }
                LinearGradient(colors: [Palette.ground, Palette.ground.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 36)
            }
            .padding(.bottom, -36)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var indicator: some View {
        let index = bins.firstIndex(of: current) ?? 0
        return HStack(spacing: 10) {
            ForEach(bins) { bin in
                LidSphere(bin: bin, size: 8, raised: bin == current)
                    .opacity(bin == current ? 1 : 0.55)
                    .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("%@, page %lld of %lld", current.displayName, index + 1, bins.count))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: turn(to: index + 1)
            case .decrement: turn(to: index - 1)
            @unknown default: break
            }
        }
    }

    private func turn(to index: Int) {
        guard bins.indices.contains(index) else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85)) { page = bins[index] }
    }

    private func settlePage() {
        if !bins.contains(page), let first = bins.first { page = first }
    }
}

/// A council page to show in Safari inside the app.
struct GuideLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
