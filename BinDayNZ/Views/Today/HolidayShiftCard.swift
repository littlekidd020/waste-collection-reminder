import SwiftUI

/// One card per upcoming public holiday that touches the saved schedule. Where the council publishes
/// one clear rule (Auckland), applying records it as one-off changes; elsewhere the card lists the
/// affected collections and links the council's own notice. The regular cycle is never touched.
struct HolidayShiftCard: View {
    let suggestion: HolidaySuggestion
    let council: Council
    let onApply: () -> Void
    let onDismiss: () -> Void

    private var holidayDate: String { collectionDateLabel(suggestion.holiday.date, template: "EEEE d MMMM") }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("Holiday collection change"), systemImage: "calendar.badge.exclamationmark")
                .font(.headline)
            if suggestion.policy.appliesAutomatically {
                Text(L("%@ is %@. Auckland Council: a collection on or after a public holiday runs one day later that week.",
                       suggestion.holiday.name, holidayDate))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L("%@ is %@. Collections that week may change. Check the %@ notice before putting bins out.",
                       suggestion.holiday.name, holidayDate, council.name))
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestion.moves) { move in
                    HStack(alignment: .center, spacing: 10) {
                        BinLidChip(bin: move.binType, size: 22)
                        Group {
                            if suggestion.policy.appliesAutomatically {
                                Text(L("%@ moves from %@ to %@", move.binType.displayName,
                                       collectionDateLabel(move.original, template: "EEE d MMM"),
                                       collectionDateLabel(move.replacement, template: "EEE d MMM")))
                            } else {
                                Text(L("%@ on %@", move.binType.displayName, collectionDateLabel(move.original, template: "EEE d MMM")))
                            }
                        }
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { actions }
                VStack(alignment: .leading, spacing: 8) { actions }
            }
            if suggestion.policy.appliesAutomatically {
                Text(L("Check the council notice for your property. City centre bags, island and private services differ."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L("If your council moves a collection, add it as a one-off change in Change schedule."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Link(L("Source: %@", council.name), destination: suggestion.policy.sourceURL)
                .font(.footnote)
                .frame(minHeight: 44, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var actions: some View {
        if suggestion.policy.appliesAutomatically {
            Button(L("Apply to my schedule"), action: onApply)
                .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill).controlSize(.large)
            Button(L("Not for me"), action: onDismiss)
                .buttonStyle(.bordered).controlSize(.large)
        } else {
            Link(L("Open council notice"), destination: suggestion.policy.sourceURL)
                .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill).controlSize(.large)
            Button(L("Got it"), action: onDismiss)
                .buttonStyle(.bordered).controlSize(.large)
        }
    }
}
