import SwiftUI

/// Info view — bin guide and inorganic collection information.
struct InfoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Bin guides
                    ForEach(BinType.allCases) { binType in
                        BinGuideCard(binType: binType)
                    }

                    // Tips section
                    tipsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle(String(localized: "Bin Guide"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Tips"))
                .font(.headline)
                .foregroundStyle(.primary)

            tipRow(
                icon: "clock.fill",
                title: String(localized: "Put bins out the night before"),
                detail: String(localized: "Collection starts early! Have your bin at the kerb by 7am.")
            )

            tipRow(
                icon: "arrow.up.to.line.compact",
                title: String(localized: "Lid must close"),
                detail: String(localized: "Bins with lids that don't close won't be collected.")
            )

            tipRow(
                icon: "drop.fill",
                title: String(localized: "Rinse containers"),
                detail: String(localized: "Quickly rinse food containers before recycling.")
            )

            tipRow(
                icon: "wind",
                title: String(localized: "Windy days"),
                detail: String(localized: "Place your bin where it won't blow away. Consider weighting the lid.")
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private func tipRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.green)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - BinGuideCard

/// Expandable card showing what goes in/out of a bin type.
struct BinGuideCard: View {
    let binType: BinType
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header — always visible
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    Text(binType.icon)
                        .font(.title)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(binType.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)

                        if binType == .inorganic {
                            Text(String(localized: "Special collection"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()

                    // Accepted items
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "✅ Yes, put these in"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)

                        ForEach(binType.acceptedItems, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(.green.opacity(0.7))
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Rejected items
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "❌ Not in this bin"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)

                        ForEach(binType.rejectedItems, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.red.opacity(0.7))
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(binType.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(binType.color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
