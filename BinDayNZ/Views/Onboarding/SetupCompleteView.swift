import SwiftUI
import SwiftData

/// Shown once, right after setup saves. The schedule is done; this screen is about keeping it
/// in front of the household: the next collection standing on the floor, the widget and a share link.
struct SetupCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [UserProfile]
    @State private var binsIn = false
    @State private var restIn = false
    private let engine = ScheduleEngine()

    private var zone: CollectionZone? { profiles.first.flatMap { DataService.shared.zone(for: $0) } }
    private var council: Council? { profiles.first.flatMap { DataService.shared.council(for: $0) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("You're set"))
                        .kerbFont(34, .semibold, relativeTo: .largeTitle)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    if let zone, let next = engine.nextCollection(for: zone) {
                        nextCollection(date: next.date, bins: engine.binsCollectedOn(date: next.date, zone: zone))
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Hairline().padding(.vertical, 24)
                        block(symbol: "rectangle.on.rectangle", title: L("Add the widget"),
                              message: L("See your next collection without opening the app.")) {
                            Text(L("Touch and hold your Home Screen, tap the plus button, then search for Bin Day NZ."))
                                .kerbFont(15, relativeTo: .subheadline)
                                .foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let zone, let text = ScheduleLink.shareText(for: zone, council: council) {
                            Hairline().padding(.vertical, 24)
                            block(symbol: "square.and.arrow.up", title: L("Share with your household"),
                                  message: L("Everyone on your street has the same bin days. Send your schedule so they can add it in one tap.")) {
                                ShareLink(item: text) {
                                    Label(L("Share with your household"), systemImage: "square.and.arrow.up")
                                        .kerbFont(15, .semibold, relativeTo: .subheadline)
                                        .foregroundStyle(Palette.ink)
                                        .frame(minHeight: 36)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.capsule)
                                .controlSize(.large)
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .opacity(restIn ? 1 : 0)
                    .offset(y: restIn || reduceMotion ? 0 : 8)
                }
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background { LinenGround() }
            .safeAreaInset(edge: .bottom) {
                Button { dismiss() } label: {
                    KerbPrimaryButtonLabel(title: L("Done"))
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(Palette.accent)
                .frame(maxWidth: 600)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(alignment: .top) {
                    LinearGradient(colors: [Palette.ground.opacity(0), Palette.ground.opacity(0.94)],
                                   startPoint: .top, endPoint: .init(x: 0.5, y: 0.35))
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: enter)
        }
        .tint(Palette.accent)
    }

    // MARK: - Next collection

    private func nextCollection(date: Date, bins: [BinType]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Next collection")).kerbLabel()
                Text(collectionDateLabel(date))
                    .kerbFont(22, .semibold, relativeTo: .title2)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .accessibilityElement(children: .combine)

            BinCluster(bins: bins, objectHeight: 150)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(alignment: .bottom) {
                    GroundBand(returns: true, peak: 0.6)
                        .frame(height: 120)
                        .offset(y: 42)
                }
                .padding(.top, 28)
                .opacity(binsIn ? 1 : 0)
                .offset(y: binsIn || reduceMotion ? 0 : 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(bins) { CollectionBinRow(bin: $0) }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(restIn ? 1 : 0)
        }
    }

    // MARK: - Text blocks

    private func block<Content: View>(symbol: String, title: String, message: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title).foregroundStyle(Palette.ink)
            } icon: {
                Image(systemName: symbol).foregroundStyle(Palette.muted)
            }
            .kerbFont(17, .semibold, relativeTo: .headline)
            Text(message)
                .kerbFont(15, relativeTo: .subheadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Motion

    /// The day's bins settle onto the floor; the rows and blocks fade in after. Reduce Motion fades.
    private func enter() {
        guard !binsIn else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { binsIn = true; restIn = true }
            return
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { binsIn = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.12)) { restIn = true }
    }
}
