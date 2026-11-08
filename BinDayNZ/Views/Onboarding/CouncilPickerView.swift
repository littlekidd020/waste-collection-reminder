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
            Text(L("Council")).font(.headline)
            Button { showPicker = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "building.2").accessibilityHidden(true)
                    Text(council?.name ?? L("Choose your council"))
                        .foregroundStyle(council == nil ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Council"))
            .accessibilityValue(council?.name ?? L("Choose your council"))
            .accessibilityHint(L("Choose the council that collects your bins"))
            Text(suggested && council != nil
                 ? L("Suggested from your address. Change it if it is wrong.")
                 : L("Your council's website is where you check your collection day. The app links to it and lists the bins it offers."))
                .font(.footnote).foregroundStyle(.secondary)
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
                        Section(group.region.displayName) {
                            ForEach(group.councils) { row($0) }
                        }
                    }
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(results) { row($0) }
                }
            }
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
                    Text(council.name).foregroundStyle(.primary)
                    if !query.isEmpty {
                        Text(council.region.displayName).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if council == selection {
                    Image(systemName: "checkmark").foregroundStyle(AppTheme.accent).accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
        }
        .accessibilityAddTraits(council == selection ? [.isSelected] : [])
    }
}
