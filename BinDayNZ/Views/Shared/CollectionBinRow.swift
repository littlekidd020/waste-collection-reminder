import SwiftUI

/// A bin's name with its lid sphere, for lists and sheets. Shared by several screens.
struct CollectionBinRow: View {
    let bin: BinType
    var sphere: CGFloat = 14

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            LidSphere(bin: bin, size: sphere)
                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + sphere * 0.42 }
            Text(bin.displayName)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bin.displayName)
    }
}
