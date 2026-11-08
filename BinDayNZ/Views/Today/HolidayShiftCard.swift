import SwiftUI

/// One panel per upcoming public holiday that touches the saved schedule. Where the council publishes
/// one clear rule (Auckland), applying records it as one-off changes; elsewhere the panel lists the
/// affected collections and links the council's own notice. The regular cycle is never touched.
struct HolidayShiftCard: View {
    let suggestion: HolidaySuggestion
    let council: Council
    let onApply: () -> Void
    let onDismiss: () -> Void

    private var holidayDate: String { collectionDateLabel(suggestion.holiday.date, template: "EEEE d MMMM") }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "snowflake")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)
                Text(L("Holiday collection change")).kerbLabel(12)
            }
            .foregroundStyle(Palette.muted)
            Group {
                if suggestion.policy.appliesAutomatically {
                    Text(L("%@ is %@. Auckland Council: a collection on or after a public holiday runs one day later that week.",
                           suggestion.holiday.name, holidayDate))
                } else {
                    Text(L("%@ is %@. Collections that week may change. Check the %@ notice before putting bins out.",
                           suggestion.holiday.name, holidayDate, council.name))
                }
            }
            .kerbFont(15, relativeTo: .subheadline)
            .foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(suggestion.moves) { move in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        LidSphere(bin: move.binType, size: 9)
                            .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + 4 }
                        Group {
                            if suggestion.policy.appliesAutomatically {
                                Text(L("%@ moves from %@ to %@", move.binType.displayName,
                                       collectionDateLabel(move.original, template: "EEE d MMM"),
                                       collectionDateLabel(move.replacement, template: "EEE d MMM")))
                            } else {
                                Text(L("%@ on %@", move.binType.displayName, collectionDateLabel(move.original, template: "EEE d MMM")))
                            }
                        }
                        .kerbFont(14, relativeTo: .footnote)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { actions }
                VStack(alignment: .leading, spacing: 10) { actions }
            }
            .padding(.top, 2)

            Link(L("Source: %@", council.name), destination: suggestion.policy.sourceURL)
                .kerbFont(13, relativeTo: .footnote)
                .foregroundStyle(Palette.muted)
                .frame(minHeight: 32, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder private var actions: some View {
        if suggestion.policy.appliesAutomatically {
            Button(action: onApply) { Text(L("Apply to my schedule")).foregroundStyle(Palette.onAccent) }
                .buttonStyle(.borderedProminent).tint(Palette.accent).buttonBorderShape(.capsule).controlSize(.regular)
            Button(L("Not for me"), action: onDismiss)
                .buttonStyle(.plain).foregroundStyle(Palette.muted).frame(minHeight: 44)
        } else {
            Link(destination: suggestion.policy.sourceURL) { Text(L("Open council notice")).foregroundStyle(Palette.onAccent) }
                .buttonStyle(.borderedProminent).tint(Palette.accent).buttonBorderShape(.capsule).controlSize(.regular)
            Button(L("Got it"), action: onDismiss)
                .buttonStyle(.plain).foregroundStyle(Palette.muted).frame(minHeight: 44)
        }
    }
}

/// A gentle reminder on Today when no widget is installed two weeks after setup.
struct WidgetNudgePanel: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)
                Text(L("Add the widget")).kerbLabel(12)
            }
            .foregroundStyle(Palette.muted)
            Text(L("See your next collection without opening the app."))
                .kerbFont(15, relativeTo: .subheadline)
                .foregroundStyle(Palette.ink)
            Text(L("Touch and hold your Home Screen, tap the plus button, then search for Bin Day NZ."))
                .kerbFont(14, relativeTo: .footnote)
                .foregroundStyle(Palette.muted)
            Button(L("Not now"), action: onDismiss)
                .buttonStyle(.plain).foregroundStyle(Palette.muted).frame(minHeight: 44, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}
