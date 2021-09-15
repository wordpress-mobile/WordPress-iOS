import SwiftUI
import UIKit
import WebKit

public struct WebView: View {

    private let url: URL
    @State private var alertPresented = false

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        VStack {
            _WebView(url: url)
            VStack(spacing: 4) {
                Text("Can't find what you're looking for?").italic()
                Button {
                    self.alertPresented.toggle()
                } label: {
                    Text("Contact Support")
                }
                .alert(isPresented: $alertPresented) {
                    Alert(
                        title: Text("TODO"),
                        message: Text("This should load the Zendesk flow"),
                        dismissButton: .default(Text("Dismiss"))
                    )
                }
            }
        }
    }
}

// Credits https://gist.github.com/joshbetz/2ff5922203240d4685d5bdb5ada79105

struct _WebView: UIViewRepresentable {

    private let request: URLRequest

    init(url: URL) {
        request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
    }

    private let navigationDelegate = WebViewDelegate()
    private let webView = WKWebView()

    func makeUIView(context: UIViewRepresentableContext<Self>) -> WKWebView {
        webView.navigationDelegate = navigationDelegate
        // No need to initiate a request, it will be done when `updateUIView(_:, context:)` runs
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: UIViewRepresentableContext<Self>) {
        webView.load(request)
    }
}

class WebViewDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("webview didFinishNavigation")
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debugPrint("didStartProvisionalNavigation")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        debugPrint("webviewDidCommit")
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        debugPrint("didReceiveAuthenticationChallenge")
        completionHandler(.performDefaultHandling, nil)
    }
}
