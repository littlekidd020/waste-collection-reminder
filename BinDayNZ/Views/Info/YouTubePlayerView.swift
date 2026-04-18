import SwiftUI
import AVKit
import SafariServices

/// Inline video player for bin guide videos.
///
/// Strategy:
/// 1. If a direct video URL (MP4) is available → plays inline with AVPlayer
/// 2. Otherwise → shows YouTube thumbnail, tapping opens in-app Safari sheet
///
/// To enable true inline playback, replace the YouTube URLs in BinType.videoURL
/// with direct MP4 links (e.g. from cloud storage, your own CDN, or bundled files).
struct YouTubePlayerView: View {
    let binType: BinType
    @State private var showingSafari = false

    private var videoURL: String { binType.videoURL }

    /// Whether this is a direct video file (MP4) vs a YouTube link
    private var isDirectVideo: Bool {
        let lower = videoURL.lowercased()
        return lower.hasPrefix("file://") || lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") ||
               lower.hasSuffix(".m4v") || lower.contains(".mp4?")
    }

    private var videoID: String? {
        // First try the YouTube watch URL
        if let id = extractVideoID(from: "https://www.youtube.com/watch?v=\(youTubeID)") {
            return id
        }
        return extractVideoID(from: videoURL)
    }

    /// Explicit YouTube ID for thumbnails
    private var youTubeID: String {
        switch binType {
        case .rubbish: return "AIkjD2vszQo"
        case .recycling: return "42dWHzAqO7E"
        case .foodScraps: return "fCk0RGm-xK8"
        case .inorganic: return "vq5rAaNrevA"
        }
    }

    private var thumbnailURL: URL? {
        return URL(string: "https://img.youtube.com/vi/\(youTubeID)/hqdefault.jpg")
    }

    private var watchURL: URL? {
        return URL(string: "https://www.youtube.com/watch?v=\(youTubeID)")
    }

    var body: some View {
        if isDirectVideo, let url = URL(string: videoURL) {
            // ── Direct MP4: true inline playback ──
            InlineVideoPlayer(url: url)
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 0))
        } else {
            // ── YouTube: thumbnail + in-app Safari sheet ──
            youTubeThumbnailView
        }
    }

    // MARK: - YouTube Thumbnail

    private var youTubeThumbnailView: some View {
        Button {
            showingSafari = true
        } label: {
            ZStack {
                if let thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        case .failure:
                            placeholder
                        case .empty:
                            placeholder
                                .overlay {
                                    ProgressView()
                                        .tint(.white)
                                }
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }

                // YouTube-style play button
                Circle()
                    .fill(.red)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    }
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 3)
            }
            .clipped()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSafari) {
            if let url = watchURL {
                SafariVideoPlayer(url: url)
                    .ignoresSafeArea()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.black)
            .aspectRatio(16/9, contentMode: .fill)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(L("Tap to play"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
    }

    // MARK: - Helpers

    private func extractVideoID(from url: String) -> String? {
        if let range = url.range(of: "v=") {
            return String(url[range.upperBound...].components(separatedBy: "&").first ?? "")
        } else if url.contains("embed/") {
            return url.components(separatedBy: "embed/").last?.components(separatedBy: "?").first
        } else if url.contains("youtu.be/") {
            return url.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        return nil
    }
}

// MARK: - Inline AVPlayer (for direct MP4 URLs)

/// Plays a direct video file inline using AVPlayer.
/// Provides native iOS video controls with no YouTube restrictions.
struct InlineVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = false
        controller.videoGravity = .resizeAspect

        // Don't auto-play — let the user tap play
        controller.player?.pause()

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - Safari Fallback (for YouTube URLs)

struct SafariVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredBarTintColor = .black
        safari.preferredControlTintColor = .white
        safari.dismissButtonStyle = .close
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
