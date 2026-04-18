import SwiftUI

/// Council picker — second page of onboarding.
/// Shows supported councils as tappable and unsupported as "Coming Soon".
struct CouncilPickerView: View {
    @Binding var selectedCouncil: Council?
    let onContinue: () -> Void

    private let dataService = DataService.shared

    private var supportedCouncils: [Council] {
        dataService.supportedCouncils()
    }

    private var unsupportedCouncils: [Council] {
        dataService.allCouncils().filter { $0.zones.isEmpty }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(L("Select Your Council"))
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text(L("Choose your local council to get your collection schedule"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                // Council list
                ScrollView {
                    VStack(spacing: 12) {
                        // Supported councils
                        ForEach(supportedCouncils) { council in
                            CouncilRow(
                                council: council,
                                isSupported: true,
                                selectedCouncil: $selectedCouncil
                            )
                        }

                        if !unsupportedCouncils.isEmpty {
                            Text(L("Coming Soon"))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.tertiary)
                                .textCase(.uppercase)
                                .padding(.top, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)

                            ForEach(unsupportedCouncils) { council in
                                CouncilRow(
                                    council: council,
                                    isSupported: false,
                                    selectedCouncil: $selectedCouncil
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Continue button
                Button(action: onContinue) {
                    Text(L("Continue"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(selectedCouncil != nil ? Color.green : Color.gray.opacity(0.3))
                        )
                }
                .disabled(selectedCouncil == nil)
                .padding(.horizontal, 32)
                .animation(.default, value: selectedCouncil)

                // Page indicator
                HStack(spacing: 8) {
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.secondary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

private struct CouncilRow: View {
    let council: Council
    let isSupported: Bool
    @Binding var selectedCouncil: Council?

    var body: some View {
        Button {
            if isSupported {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedCouncil = council
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L(council.name))
                        .font(.body.weight(.medium))
                        .foregroundStyle(isSupported ? .primary : .secondary)
                    Text(council.region)
                        .font(.caption)
                        .foregroundStyle(isSupported ? .secondary : .tertiary)
                }

                Spacer()

                if isSupported {
                    if selectedCouncil?.id == council.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                            .symbolEffect(.bounce, value: selectedCouncil?.id == council.id)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.tertiary)
                            .font(.title3)
                    }
                } else {
                    Text(L("Soon"))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color(uiColor: .tertiarySystemFill))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: selectedCouncil?.id == council.id ? Color.green.opacity(0.1) : Color.black.opacity(0.05), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        selectedCouncil?.id == council.id
                        ? Color.green
                        : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(!isSupported)
    }
}
