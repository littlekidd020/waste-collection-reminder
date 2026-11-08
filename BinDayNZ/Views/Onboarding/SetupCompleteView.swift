import SwiftUI
import SwiftData

/// Shown once, right after setup saves. The schedule is done; this screen is about keeping it
/// in front of the household: the widget and a share link.
struct SetupCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    private let engine = ScheduleEngine()

    private var zone: CollectionZone? { profiles.first.flatMap { DataService.shared.zone(for: $0) } }
    private var council: Council? { profiles.first.flatMap { DataService.shared.council(for: $0) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                            .accessibilityHidden(true)
                        Text(L("You're set"))
                            .font(.largeTitle.bold())
                        if let zone, let next = engine.nextCollection(for: zone) {
                            let bins = engine.binsCollectedOn(date: next.date, zone: zone)
                            Text(L("Next collection"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text(collectionDateLabel(next.date))
                                .font(.title3.weight(.semibold))
                            ForEach(bins) { CollectionBinRow(bin: $0) }
                        }
                    }
                    .accessibilityElement(children: .combine)

                    SetupCompleteCard(symbol: "rectangle.on.rectangle", title: L("Add the widget"),
                                      message: L("See your next collection without opening the app.")) {
                        Text(L("Touch and hold your Home Screen, tap the plus button, then search for Bin Day NZ."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let zone, let text = ScheduleLink.shareText(for: zone, council: council) {
                        SetupCompleteCard(symbol: "square.and.arrow.up", title: L("Share with your household"),
                                          message: L("Everyone on your street has the same bin days. Send your schedule so they can add it in one tap.")) {
                            ShareLink(item: text) {
                                Label(L("Share with your household"), systemImage: "square.and.arrow.up")
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }
                .frame(maxWidth: 600, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Button(L("Done")) { dismiss() }
                    .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill).controlSize(.large)
                    .frame(maxWidth: 600)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(L("Done")) { dismiss() } }
            }
        }
    }
}

private struct SetupCompleteCard<Content: View>: View {
    let symbol: String
    let title: String
    let message: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// A gentle reminder on Today when no widget is installed two weeks after setup.
struct WidgetNudgeCard: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L("Add the widget"), systemImage: "rectangle.on.rectangle")
                .font(.headline)
            Text(L("See your next collection without opening the app."))
            Text(L("Touch and hold your Home Screen, tap the plus button, then search for Bin Day NZ."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(L("Not now"), action: onDismiss)
                .frame(minHeight: 44, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
