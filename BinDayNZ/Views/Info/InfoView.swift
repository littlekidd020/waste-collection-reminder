import SwiftUI

/// Locally available Auckland guides, with optional council videos and resources.
struct InfoView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedBin: BinType?

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("Bin Guide"))
                            .font(.title2.bold())
                        Text(L("Auckland Council guidance. Written guides are available offline."))
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(BinType.allCases) { bin in
                            BinGuideCard(binType: bin) { selectedBin = bin }
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text(L("Before collection"))
                            .font(.headline)
                        Label {
                            Text(L("Follow your property's collection time and placement instructions. Shared bins and apartments may have different arrangements."))
                        } icon: {
                            Image(systemName: "clock")
                        }
                        Label {
                            Text(L("Keep lids closed and leave footpaths, driveways and access to the bins clear."))
                        } icon: {
                            Image(systemName: "figure.walk")
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("Resources"))
                            .font(.headline)
                        Link(destination: URL(string: "https://www.aucklandcouncil.govt.nz/rubbish-recycling")!) {
                            resourceLabel(L("Auckland Council Website"), icon: "globe")
                        }
                        Link(destination: URL(string: "tel:093010101")!) {
                            resourceLabel(L("Report a missed collection"), icon: "phone")
                        }
                        Link(destination: URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/get-rid-unwanted-items.html")!) {
                            resourceLabel(L("Find where an item goes"), icon: "magnifyingglass")
                        }
                        NavigationLink {
                            PrivacyView()
                        } label: {
                            resourceLabel(L("Privacy and Help"), icon: "hand.raised")
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(L("Info"))
            .sheet(item: $selectedBin) { BinDetailView(binType: $0) }
        }
    }

    private func resourceLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }
}

struct BinGuideCard: View {
    let binType: BinType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: binType.systemImage)
                    .font(.title)
                    .foregroundStyle(binType.color)
                    .symbolVariant(.none)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(binType.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(binType == .inorganic ? L("Book a collection") : L("What goes in"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(binType.displayName)
        .accessibilityHint(L("Tap for details"))
    }
}

/// Shared press feedback respects Reduce Motion.
struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.78 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct BinDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let binType: BinType

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Label(binType.displayName, systemImage: binType.systemImage)
                        .font(.title2.bold())
                        .symbolVariant(.none)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(binType.guideNotes, id: \.self) { note in
                            Text(note)
                        }
                        if binType == .inorganic {
                            Link(L("Book with Auckland Council"), destination: URL(string: "https://inorganiccollections.aucklandcouncil.govt.nz/Inorganic/")!)
                                .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill)
                                .controlSize(.large)
                            Link(L("Collection terms and limits"), destination: URL(string: "https://new.aucklandcouncil.govt.nz/content/dam/ac/docs/rubbish-recycling/inorganiccollectiontermsandconditions.pdf")!)
                                .frame(minHeight: 44, alignment: .leading)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    DetailListSection(title: L("Yes, put these in"), icon: "checkmark.circle", items: binType.acceptedItems)
                    DetailListSection(title: L("Not in this bin"), icon: "xmark.circle", items: binType.rejectedItems)

                    VStack(alignment: .leading, spacing: 10) {
                        Link(destination: binType.guideSourceURL) {
                            Label(L("Source: Auckland Council"), systemImage: "arrow.up.right.square")
                        }
                        .frame(minHeight: 44, alignment: .leading)
                        if binType == .foodScraps {
                            Link(L("Food scraps collection rules"), destination: URL(string: "https://www.aucklandcouncil.govt.nz/plans-projects-policies-reports-bylaws/bylaws/docssolidwastebylawoperationalcontrols/waste-management-minimisation-bylaw-collections-control.pdf")!)
                                .frame(minHeight: 44, alignment: .leading)
                        }
                        Text(L("Guide reviewed: %@", BinType.guideReviewDate.formatted(.dateTime.day().month(.wide).year().locale(LanguageManager.shared.locale))))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(L("These are common examples. Check the council source for unusual items or changes."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let videoID = binType.youTubeVideoID, let videoURL = binType.videoURL {
                        CouncilVideoSection(videoID: videoID, videoURL: videoURL)
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(binType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) { dismiss() }
                }
            }
        }
    }
}

private struct DetailListSection: View {
    let title: String
    let icon: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CouncilVideoSection: View {
    let videoID: String
    let videoURL: URL
    @State private var showsPlayer = false
    @State private var failedToLoad = false
    @State private var loadID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("Council video (English)"))
                .font(.headline)
            Text(L("Optional. Loading a video connects to YouTube. The written guide works without an internet connection."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if showsPlayer {
                YouTubePlayerView(videoID: videoID) { failedToLoad = true }
                    .id(loadID)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(.black)
                    .accessibilityLabel(L("Council video player"))
                if failedToLoad {
                    Label(L("The video could not load. Check your connection, retry, or read the guide above."), systemImage: "wifi.exclamationmark")
                        .font(.subheadline)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { playerControls }
                    VStack(alignment: .leading, spacing: 12) { playerControls }
                }
            } else {
                Button {
                    failedToLoad = false
                    showsPlayer = true
                } label: {
                    Label(L("Load video"), systemImage: "play.rectangle")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            Link(L("Open on YouTube"), destination: videoURL)
                .frame(minHeight: 44, alignment: .leading)
            Text(L("If playback is unavailable here, open YouTube. Captions are controlled in the player and may not be available in your language."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var playerControls: some View {
        Button(L("Retry video")) {
            failedToLoad = false
            loadID = UUID()
        }
        .frame(minHeight: 44)
        Button(L("Close video")) { showsPlayer = false }
            .frame(minHeight: 44)
    }
}
