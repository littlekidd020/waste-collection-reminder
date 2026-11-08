import SwiftUI

/// Placeholder. Each direction replaces this file with its own shell (tab bar, navigation) and screens.
struct DirectionRoot: View {
    let screen: Screen
    var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()
            Grain()
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Scaffold")
                    .font(.system(size: 44, weight: .light, design: .default))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 18) {
                    ForEach(Bin.allCases) { LidSphere(bin: $0, size: 36) }
                    LidSphere(bin: nil, size: 36)
                }
                Button("Glass button") {}
                    .buttonStyle(.glass)
                Text(Sample.list(Sample.next.bins))
                    .foregroundStyle(Palette.muted)
            }
        }
    }
}
