import SwiftUI
import WebKit

struct PluginInfoSectionContentView: View {
    let title: String
    let content: String

    var body: some View {
        WebView(content: content)
            .navigationTitle(title)
    }
}

private struct WebView: UIViewRepresentable {
    let content: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
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
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """

        webView.loadHTMLString(styledHTML, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
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
    }
}
