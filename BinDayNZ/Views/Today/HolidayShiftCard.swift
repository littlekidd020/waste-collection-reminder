import SwiftUI

/// One card per upcoming public holiday that touches the saved schedule. Applying records the
/// council's one-day-later rule as one-off changes; the regular cycle is untouched.
struct HolidayShiftCard: View {
    let suggestion: HolidaySuggestion
    let onApply: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("Holiday collection change"), systemImage: "calendar.badge.exclamationmark")
                .font(.headline)
            Text(L("%@ is %@. Auckland Council: a collection on or after a public holiday runs one day later that week.",
                   suggestion.holiday.name, collectionDateLabel(suggestion.holiday.date, template: "EEEE d MMMM")))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestion.moves) { move in
                    HStack(alignment: .center, spacing: 10) {
                        BinLidChip(bin: move.binType, size: 22)
                        Text(L("%@ moves from %@ to %@", move.binType.displayName,
                               collectionDateLabel(move.original, template: "EEE d MMM"),
                               collectionDateLabel(move.replacement, template: "EEE d MMM")))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { actions }
                VStack(alignment: .leading, spacing: 8) { actions }
            }
            Text(L("Check the council notice for your property. City centre bags, island and private services differ."))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Link(L("Source: Auckland Council"), destination: PublicHoliday.sourceURL)
                .font(.footnote)
                .frame(minHeight: 44, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var actions: some View {
        Button(L("Apply to my schedule"), action: onApply)
            .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill).controlSize(.large)
        Button(L("Not for me"), action: onDismiss)
            .buttonStyle(.bordered).controlSize(.large)
    }
}
