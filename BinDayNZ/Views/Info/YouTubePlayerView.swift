import SwiftUI
import WebKit

/// Created only after the user chooses to load a council video.
struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    let onFailure: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(videoID: videoID, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.load(Self.request(for: videoID))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onFailure = onFailure
        guard context.coordinator.videoID != videoID else { return }
        context.coordinator.videoID = videoID
        webView.load(Self.request(for: videoID))
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.pauseAllMediaPlayback(completionHandler: nil)
        webView.stopLoading()
        webView.navigationDelegate = nil
    }

    static func request(for videoID: String) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube-nocookie.com"
        components.path = "/embed/\(videoID)"
        components.queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "controls", value: "1"),
            URLQueryItem(name: "rel", value: "0")
        ]

        var request = URLRequest(url: components.url!, timeoutInterval: 20)
        // YouTube requires the iOS client's bundle ID as its HTTPS referrer.
        // https://developers.google.com/youtube/terms/required-minimum-functionality
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue("https://\(bundleID.lowercased())", forHTTPHeaderField: "Referer")
        }
        return request
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var videoID: String
        var onFailure: () -> Void

        init(videoID: String, onFailure: @escaping () -> Void) {
            self.videoID = videoID
            self.onFailure = onFailure
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        private func report(_ error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            onFailure()
        }
    }
}
