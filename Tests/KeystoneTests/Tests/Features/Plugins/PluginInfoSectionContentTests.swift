import Testing
import WebKit

@testable import WordPress

@MainActor
struct PluginInfoSectionContentTests {
    @Test func usesTheBaseURLAsTheDocumentOrigin() async throws {
        let webView = try await load("<p>Text</p>", baseURL: URL(string: "https://wordpress.org/plugins/hello-dolly/"))

        let origin = try await webView.evaluateJavaScript("location.origin") as? String

        #expect(origin == "https://wordpress.org")
    }

    @Test func fitsAWideEmbedInTheScreenWidth() async throws {
        let webView = try await load(#"<iframe width="750" height="422" style="border:0;"></iframe>"#, baseURL: nil)

        let script = """
            (() => {
                const { width, height } = document.querySelector('iframe').getBoundingClientRect();
                return { width, height, pageWidth: document.documentElement.scrollWidth, screenWidth: innerWidth };
            })()
            """
        let values = try #require(await webView.evaluateJavaScript(script) as? [String: Double])
        let width = try #require(values["width"])
        let height = try #require(values["height"])

        // The body has a margin of 16 on each side.
        #expect(width == 402 - 32)
        #expect(abs(height - width * 9 / 16) < 1)
        #expect(values["pageWidth"] == values["screenWidth"])
    }

    @Test func usesTheTextColorOfTheInterfaceStyle() async throws {
        let light = try await textColor(in: .light)
        let dark = try await textColor(in: .dark)

        #expect(light == "rgb(0, 0, 0)")
        #expect(dark == "rgb(255, 255, 255)")
    }

    /// Web views only pick up the interface style from a window.
    private func textColor(in style: UIUserInterfaceStyle) async throws -> String? {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 800))
        window.overrideUserInterfaceStyle = style
        window.isHidden = false
        defer { window.isHidden = true }

        let webView = WKWebView(frame: window.bounds)
        window.addSubview(webView)
        try await NavigationDelegate().load("<p>Text</p>", baseURL: nil, in: webView)

        return try await webView.evaluateJavaScript("getComputedStyle(document.body).color") as? String
    }

    private func load(_ content: String, baseURL: URL?) async throws -> WKWebView {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 402, height: 800))
        let delegate = NavigationDelegate()
        try await delegate.load(content, baseURL: baseURL, in: webView)
        return webView
    }
}

/// Resumes when the web view finishes or fails its navigation.
@MainActor
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?

    func load(_ content: String, baseURL: URL?, in webView: WKWebView) async throws {
        webView.navigationDelegate = self
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            webView.loadPluginInfoSection(content, baseURL: baseURL)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finish(.success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<Void, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
