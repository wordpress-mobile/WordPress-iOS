import SwiftUI
import UIKit
import WebKit

// This implementation is based upon
// https://gist.github.com/joshbetz/2ff5922203240d4685d5bdb5ada79105

struct WebView: UIViewRepresentable {

    private let request: URLRequest
    @EnvironmentObject var eventLogger: EventLogger

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

        guard let url = request.url else { return } // `.url` should always be available
        eventLogger.logHelpPageLoaded(with: url)
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
