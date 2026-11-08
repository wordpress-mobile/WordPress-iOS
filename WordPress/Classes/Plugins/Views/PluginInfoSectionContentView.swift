import SwiftUI
import WebKit

struct PluginInfoSectionContentView: View {
    let title: String
    let content: String

    /// The plugin's WordPress.org page, which is where `content` comes from.
    ///
    /// It gives the document a web origin, which WebKit sends as the HTTP referrer (`https://wordpress.org/`,
    /// without the path). YouTube embeds show "Error 153" without one:
    /// https://developers.google.com/youtube/terms/required-minimum-functionality#set-the-referer
    let baseURL: URL?

    var body: some View {
        WebView(content: content, baseURL: baseURL)
            .navigationTitle(title)
    }
}

private struct WebView: UIViewRepresentable {
    let content: String
    let baseURL: URL?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadPluginInfoSection(content, baseURL: baseURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .other {
                return .allow
            }

            if let url = navigationAction.request.url {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }

            return .cancel
        }

        /// Embeds such as the YouTube player open links with `window.open`, which doesn't go through the
        /// navigation policy above, and which WebKit ignores unless this method is implemented.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            return nil
        }
    }
}

extension WKWebView {
    func loadPluginInfoSection(_ content: String, baseURL: URL?) {
        // WordPress.org embeds are 750x422 iframes. Browsers don't derive an aspect ratio from an iframe's
        // size attributes, so `height: auto` needs an explicit one to keep the player's shape.
        let styledHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    :root {
                        color-scheme: light dark;
                    }
                    body {
                        font-family: -apple-system;
                        font-size: 16px;
                        line-height: 1.5;
                        margin: 16px;
                        padding: 0;
                    }
                    img {
                        max-width: 100%;
                        height: auto;
                    }
                    iframe {
                        max-width: 100%;
                        height: auto;
                        aspect-ratio: 16 / 9;
                    }
                </style>
            </head>
            <body>
                \(content)
            </body>
            </html>
            """

        loadHTMLString(styledHTML, baseURL: baseURL)
    }
}
