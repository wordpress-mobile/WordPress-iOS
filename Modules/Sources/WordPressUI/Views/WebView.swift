import SwiftUI
import WebKit

public struct WebView: UIViewRepresentable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> WKWebView {
        let wkwebView = WKWebView()
        let request = URLRequest(url: url)
        wkwebView.load(request)
        return wkwebView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Do nothing
    }
}
