import SwiftUI

/// A bin's lid colour as a small matte sphere. Shared by the app and the widget so the same
/// object identifies a bin on every surface. The name always accompanies it.
struct BinLidChip: View {
    let bin: BinType
    var size: CGFloat = 14

    var body: some View {
        LidSphere(bin: bin, size: size)
            .frame(width: size, height: size + size * 0.3, alignment: .top)
            .accessibilityHidden(true)
    }
}
