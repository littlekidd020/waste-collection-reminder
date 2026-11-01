import SwiftUI
import SafariServices

/// Opens a council page without leaving the app, so returning to the schedule editor is one swipe.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = UIColor(AppTheme.accent)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
