import Foundation
import CocoaLumberjack
import WebKit

class WPRichTextEmbed: UIView, WPRichTextMediaAttachment {
    typealias successBlock = ((WPRichTextEmbed)->Void)


    // MARK: Properties
    private var internalDocumentHeight: CGFloat = 0.0
    @objc var fixedHeight: CGFloat = 0.0
    @objc var attachmentSize = CGSize.zero
    @objc var documentSize: CGSize {
        get {
            var size = webView.scrollView.contentSize
            if internalDocumentHeight > 0.0 {
                size.height = internalDocumentHeight
            }
            return size
        }
    }
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
    }


    // MARK: Public Methods

    func contentSize() -> CGSize {
        if webView.superview == nil {
            return CGSize(width: 1.0, height: 1.0)
        }

        // embeds, unlike images, typically have no intrinsic content size that we can use to fall back on
        if fixedHeight > 0 {
            return CGSize(width: CGFloat.greatestFiniteMagnitude, height: fixedHeight)
        }

        if !attachmentSize.equalTo(CGSize.zero) {
            return attachmentSize
        }

        return documentSize
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
        let htmlString = String(format: "<html><head><meta name=\"viewport\" content=\"width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" /><style>html, body { margin: 0; padding: 0; } video { width: 100vw; height: auto; }</style></head><body>%@</body></html>", html)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    /// Query the webView for its internal document's scrollHeight and pass the
    /// value to the supplied completion block.
    ///
    private func fetchInternalDocumentHeight(_ completionHandler: @escaping ((CGFloat)->Void)) {
        webView.evaluateJavaScript("document.documentElement.scrollHeight") { (result, _) in
            guard let height = result as? CGFloat else {
                completionHandler(0)
                return
            }
            completionHandler(height)
        }
    }

    /// Called when loading is finished and the viewport should be updated.
    /// Adds the webView to the view hierarchy so its visible. Fetches the
    /// internal document height now that content is fully loaded.
    /// Finally, call our success block.
    ///
    private func onLoadingComplete() {
        webView.frame = bounds
        addSubview(webView)

        fetchInternalDocumentHeight { [weak self] height in
            guard let strongSelf = self else {
                return
            }
            strongSelf.internalDocumentHeight = height
            if let callback = strongSelf.success {
                callback(strongSelf)
            }
            strongSelf.success = nil
        }
    }

    /// Override the viewport settings of the loaded content so we're sure to render correctly.
    ///
    private func updateDocumentViewPortIfNeeded(_ completionHandler: @escaping (()->Void)) {
        // Make sure that any viewport meta tag does not have a min scale incase we're display smaller than the device width.
        let viewport =  "var tid = setInterval( function () {" +
            "if ( document.readyState !== 'complete' ) return;" +
            "   clearInterval( tid );" +
            "   viewport = document.querySelector('meta[name=viewport]'); " +
            "   if (viewport) {" +
            "       viewport.setAttribute('content', 'width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');" +
            "   }" +
        "}, 100 );"
        webView.evaluateJavaScript(viewport) {(_, _) in
            completionHandler()
        }
    }

}

// MARK: WebView delegate methods
extension WPRichTextEmbed: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // We're fully loaded so we can unassign the delegate.
        webView.navigationDelegate = nil
        updateDocumentViewPortIfNeeded {[weak self] in
            self?.onLoadingComplete()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let url = contentURL {
            DDLogError("RichTextEmbed failed to load content URL: \(url).")
        }
        DDLogError("Error: \(error.localizedDescription)")
    }

}
