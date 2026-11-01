import SwiftUI

/// A bin's lid colour as a small filled disc with its symbol. Shared by the app and the widget
/// so the same glyph identifies a bin on every surface. The name always accompanies it.
struct BinLidChip: View {
    let bin: BinType
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: bin.systemImage)
            .symbolVariant(.none)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(bin.lidForeground)
            .frame(width: size, height: size)
            .background(bin.lidFill, in: Circle())
            .accessibilityHidden(true)
    }
}
