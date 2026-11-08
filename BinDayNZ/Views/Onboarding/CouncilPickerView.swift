import SwiftUI

/// The council row used in setup and Change schedule: the current choice, where it came from,
/// and a sheet to change it. The council decides which links and bins the app shows; it never
/// sets collection dates.
struct CouncilRow: View {
    @Binding var council: Council?
    /// True while the choice came from the address rather than the person.
    var suggested: Bool = false
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("Council")).kerbLabel()
            Button { showPicker = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "building.2")
                        .foregroundStyle(Palette.muted)
                        .accessibilityHidden(true)
                    Text(council?.name ?? L("Choose your council"))
                        .kerbFont(17, relativeTo: .body)
                        .foregroundStyle(council == nil ? Palette.muted : Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.horizontal, 16)
                .background(Palette.surface, in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.line, lineWidth: 0.5) }
                .contentShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Council"))
            .accessibilityValue(council?.name ?? L("Choose your council"))
            .accessibilityHint(L("Choose the council that collects your bins"))
            Text(suggested && council != nil
                 ? L("Suggested from your address. Change it if it is wrong.")
                 : L("Your council's website is where you check your collection day. The app links to it and lists the bins it offers."))
                .kerbFootnote()
        }
        .sheet(isPresented: $showPicker) {
            CouncilPickerView(selection: $council)
        }
    }
}

/// Every council, grouped by region, with search. Selecting one closes the sheet.
struct CouncilPickerView: View {
    @Binding var selection: Council?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [Council] { CouncilDirectory.search(query) }

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    ForEach(CouncilDirectory.grouped, id: \.region) { group in
                        Section {
                            ForEach(group.councils) { row($0) }
                        } header: { KerbSectionHeader(group.region.displayName) }
                        .kerbFormRows()
                    }
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    Section {
                        ForEach(results) { row($0) }
                    }
                    .kerbFormRows()
                }
            }
            .kerbFormGround()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: L("Search councils or towns"))
            .navigationTitle(L("Choose your council"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("Cancel")) { dismiss() } }
            }
        }
    }

    private func row(_ council: Council) -> some View {
        Button {
            selection = council
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(council.name).foregroundStyle(Palette.ink)
                    if !query.isEmpty {
                        Text(council.region.displayName)
                            .kerbFont(13, relativeTo: .footnote)
                            .foregroundStyle(Palette.muted)
                    }
                }
                Spacer()
                if council == selection {
                    Image(systemName: "checkmark").fontWeight(.semibold).foregroundStyle(Palette.accent).accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(council == selection ? [.isSelected] : [])
    }
}
