import Foundation
import CocoaLumberjack
import WebKit

class WPRichTextEmbed: UIView, WPRichTextMediaAttachment {
    typealias successBlock = ((WPRichTextEmbed)->Void)

    // MARK: Properties
    private var internalDocumentSize = CGSize.zero

    @objc var success: successBlock?
    var linkURL: URL?
    var contentURL: URL?
    @objc var webView: WKWebView

    override var frame: CGRect {
        didSet {
            // If Voice Over is enabled, the OS will query for the accessibilityPath
            // to know what region of the screen to highlight. If the path is nil
            // the OS should fall back to computing based on the frame but this
            // may be bugged. Setting the accessibilityPath avoids a crash.
            accessibilityPath = UIBezierPath(rect: frame)
        }
    }


    // MARK: LifeCycle

    override init(frame: CGRect) {
        // A small starting frame to avoid being sized too tall
        webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0))

        super.init(frame: frame)

        clipsToBounds = true
        configureWebView()
    }

    required init?(coder aDecoder: NSCoder) {
        if let decodedWebView = aDecoder.decodeObject(forKey: "webView") as? WKWebView {
            webView = decodedWebView
        } else {
            webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0))
        }

        super.init(coder: aDecoder)

        configureWebView()
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(webView, forKey: "webView")

        super.encode(with: aCoder)
    }


    // MARK: Configuration

    @objc func configureWebView() {
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self

        guard
            let scriptPath = Bundle.main.path(forResource: "richEmbedScript", ofType: "js"),
            let scriptText = try? String(contentsOfFile: scriptPath) else {
                return
        }

        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "observer")
        let script = WKUserScript(source: scriptText, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script)
    }


    // MARK: Public Methods

    func contentSize() -> CGSize {
        if webView.superview == nil {
            return CGSize(width: 1.0, height: 1.0)
        }

        if internalDocumentSize == .zero {
            return webView.scrollView.contentSize
        }

        return internalDocumentSize
    }

    @objc func loadContentURL(_ url: URL) {
        var url = url
        if var components = URLComponents(string: url.absoluteString) {
                if components.scheme == nil {
                    components.scheme = "http"
                }
            if  let componentStr = components.string,
                let componentURL = URL(string: componentStr) {
                    url = componentURL
            }
        }

        contentURL = url
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc func loadHTMLString(_ html: NSString) {
        guard
            let templatePath = Bundle.main.path(forResource: "richEmbedTemplate", ofType: "html"),
            let templateString = try? String(contentsOfFile: templatePath) else {
                DDLogError("RichTextEmbed: Failed to load template html for embed.")
                return
        }

        let htmlString = String(format: templateString, html)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    /// Called when loading is finished and the viewport should be updated.
    /// Adds the webView to the view hierarchy so its visible. Fetches the
    /// internal document height now that content is fully loaded.
    /// Finally, call our success block.
    ///
    private func onLoadingComplete() {
        webView.frame = bounds
        addSubview(webView)
    }

}

// MARK: WebView delegate methods
extension WPRichTextEmbed: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // We're fully loaded so we can unassign the delegate.
        webView.navigationDelegate = nil
        onLoadingComplete()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let url = contentURL {
            DDLogError("RichTextEmbed failed to load content URL: \(url).")
        }
        DDLogError("Error: \(error.localizedDescription)")
    }

}

extension WPRichTextEmbed: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        defer {
            success?(self)
            success = nil
        }

        guard
            let str = message.body as? String else {
                DDLogError("RichTextEmbed: Unable to read script tmessage.")
                return
        }

        let arr = str.split(separator: ",")
        guard
            let width = Int(arr[0]),
            let height = Int(arr[1]) else {
                return
        }

        let size = CGSize(width: width, height: height)
        internalDocumentSize = size
    }

}
