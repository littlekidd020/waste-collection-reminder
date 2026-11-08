import SwiftUI

/// Auckland Council's optional video for a bin. Nothing loads from YouTube until the person asks.
struct CouncilVideoSection: View {
    let videoID: String
    let videoURL: URL
    let open: (URL) -> Void

    @State private var showsPlayer = false
    @State private var failedToLoad = false
    @State private var loadID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("Council video (English)"))
                .kerbLabel()
                .accessibilityAddTraits(.isHeader)
            Text(L("Optional. Loading a video connects to YouTube. The written guide works without an internet connection."))
                .kerbFont(15, relativeTo: .subheadline)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            if showsPlayer {
                YouTubePlayerView(videoID: videoID) { failedToLoad = true }
                    .id(loadID)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Palette.ink)
                    .clipShape(.rect(cornerRadius: 24))
                    .accessibilityLabel(L("Council video player"))
                if failedToLoad {
                    Text(L("The video could not load. Check your connection, retry, or read the guide above."))
                        .kerbFont(15, relativeTo: .subheadline)
                        .foregroundStyle(Palette.attention)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { playerControls }
                    VStack(alignment: .leading, spacing: 12) { playerControls }
                }
            } else {
                Button {
                    failedToLoad = false
                    showsPlayer = true
                } label: {
                    Label(L("Load video"), systemImage: "play.fill")
                        .kerbFont(15, .semibold, relativeTo: .subheadline)
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 6)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
            }
            Button { open(videoURL) } label: {
                Text(L("Open on YouTube"))
                    .kerbFont(15, .medium, relativeTo: .subheadline)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityAddTraits(.isLink)
            Text(L("If playback is unavailable here, open YouTube. Captions are controlled in the player and may not be available in your language."))
                .kerbFont(13, relativeTo: .footnote)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var playerControls: some View {
        Button {
            failedToLoad = false
            loadID = UUID()
        } label: {
            Text(L("Retry video")).kerbFont(15, .medium, relativeTo: .subheadline).foregroundStyle(Palette.ink).frame(minHeight: 36)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        Button { showsPlayer = false } label: {
            Text(L("Close video")).kerbFont(15, .medium, relativeTo: .subheadline).foregroundStyle(Palette.ink).frame(minHeight: 36)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
    }
}
