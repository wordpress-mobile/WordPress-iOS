import Foundation

/// A WKWebView used to save post content to be available when offline
/// The mechanism is quite simple: open the post in a hidden webview so the images are cached
///
class OfflineReaderWebView: ReaderWebView {
    func saveForLater(_ post: ReaderPost, viewController: UIViewController) {
        guard let contentForDisplay = post.contentForDisplay() else {
            return
        }

        navigationDelegate = self

        frame = CGRect(x: 0, y: 0, width: viewController.view.frame.width, height: viewController.view.frame.height)

        isHidden = true

        viewController.view.addSubview(self)

        load(contentForDisplay)
    }

    private func load(_ string: String) {
        // Remove all srcset from the images, only the URL in the src tag will be cached
        let content = super.formattedContent(string, additionalJavaScript: jsToRemoveSrcSet)

        super.loadHTMLString(content, baseURL: Bundle.wordPressSharedBundle.bundleURL)
    }
}

extension OfflineReaderWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // We wait 5 secs before removing the WebView to give it time to be rendered
        // If its removed before it was rendered, the images won't be cached
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.removeFromSuperview()
        }
    }
}
