import Foundation

/// A WKWebView used to save post content to be available when offline
/// The mechanism is quite simple: open the post in a hidden webview so the images are cached
///
class OfflineReaderWebView: ReaderWebView {
    func saveForLater(_ string: String) {
        navigationDelegate = self

        // Remove all srcset from the images, only the URL in the src tag will be cached
        let content = super.formattedContent(string, additionalJavaScript: """
            document.querySelectorAll('img').forEach((el) => {el.removeAttribute('srcset')})
        """)

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
