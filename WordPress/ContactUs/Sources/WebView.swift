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
            VStack {
                Text("Can't find what you're looking for?").italic()
                Button {
                    self.alertPresented.toggle()
                } label: {
                    Text("Contact Support")
                }
                .alert(isPresented: $alertPresented, content: {
                    Alert(
                        title: Text("TODO"),
                        message: Text("This should load the Zendesk flow"),
                        dismissButton: .default(Text("Dismiss"))
                    )
                })
            }
        }
    }
}

struct _WebView: UIViewRepresentable {
    let url: URL
    let navigationHelper = WebViewHelper()

    func makeUIView(context: UIViewRepresentableContext<Self>) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = navigationHelper

        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)

        return webview
    }

    func updateUIView(_ webview: WKWebView, context: UIViewRepresentableContext<Self>) {
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)
    }
}

class WebViewHelper: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webview didFinishNavigation")
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("didStartProvisionalNavigation")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webviewDidCommit")
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("didReceiveAuthenticationChallenge")
        completionHandler(.performDefaultHandling, nil)
    }
}
