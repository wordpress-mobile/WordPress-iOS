import Foundation
import CocoaLumberjack

class WPRichTextEmbed: UIView, UIWebViewDelegate, WPRichTextMediaAttachment {
    typealias successBlock = ((WPRichTextEmbed)->Void)


    // MARK: Properties

    var fixedHeight: CGFloat = 0.0
    var attachmentSize = CGSize.zero
    var documentSize: CGSize {
        get {
            var contentSize = webView.scrollView.contentSize
            if let heightStr = webView.stringByEvaluatingJavaScript(from: "document.documentElement.scrollHeight") {
                if let height = NumberFormatter().number(from: heightStr) {
                    contentSize.height = CGFloat(height)
                }
            }
            return contentSize
        }
    }
    var success: successBlock?
    var linkURL: URL?
    var contentURL: URL?
    var webView: UIWebView

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
        webView = UIWebView(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0))

        super.init(frame: frame)

        clipsToBounds = true
        configureWebView()
    }

    required init?(coder aDecoder: NSCoder) {
        if let decodedWebView = aDecoder.decodeObject(forKey: "webView") as? UIWebView {
            webView = decodedWebView
        } else {
            webView = UIWebView(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0))
        }

        super.init(coder: aDecoder)

        configureWebView()
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(webView, forKey: "webView")

        super.encode(with: aCoder)
    }


    // MARK: Configuration

    func configureWebView() {
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.isScrollEnabled = false
        webView.scalesPageToFit = true
        webView.delegate = self
    }


    // MARK: Public Methods

    func contentSize() -> CGSize {
        if webView.superview == nil {
            return CGSize(width: 1.0, height: 1.0)
        }

        // embeds, unlike images, typically have no intrinsic content size that we can use to fall back on
        if (fixedHeight > 0) {
            return CGSize(width: CGFloat.greatestFiniteMagnitude, height: fixedHeight)
        }

        if !attachmentSize.equalTo(CGSize.zero) {
            return attachmentSize
        }

        return documentSize
    }

    func contentRatio() -> CGFloat {
        if (fixedHeight > 0) {
            return 0.0
        }

        if !attachmentSize.equalTo(CGSize.zero) {
            return attachmentSize.width / attachmentSize.height
        }

        if (!documentSize.equalTo(CGSize.zero)) {
            return documentSize.width / documentSize.height
        }

        return 0.0
    }

    func loadContentURL(_ url: URL) {
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
        webView.loadRequest(request)
    }

    func loadHTMLString(_ html: NSString) {
        let htmlString = String(format: "<html><head><meta name=\"viewport\" content=\"width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" /></head><body>%@</body></html>", html)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }


    func checkIfDoneLoading() {
        if webView.isLoading {
            return
        }

        if let callback = success {
            callback(self)
        }
        success = nil
        webView.delegate = nil
    }

    // MARK: WebView delegate methods

    func webViewDidFinishLoad(_ webView: UIWebView) {
        // Add the webView as a subview if it hasn't been already.
        if webView.superview == nil {
            // Make sure that any viewport meta tag does not have a min scale incase we're display smaller than the device width.
            let viewport =  "var tid = setInterval( function () {" +
                "if ( document.readyState !== 'complete' ) return;" +
                "   clearInterval( tid );" +
                "   viewport = document.querySelector('meta[name=viewport]'); " +
                "   if (viewport) {" +
                "       viewport.setAttribute('content', 'width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');" +
                "   }" +
                "}, 100 );"
            webView.stringByEvaluatingJavaScript(from: viewport)

            webView.frame = bounds
            addSubview(webView)
        }

        // The webViewDidFinishLoad method can be called many times for a single
        // web page. Wait a brief moment then check if the webview is done loading content.
        let delayTime = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
            self?.checkIfDoneLoading()
        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if let url = contentURL {
            DDLogError("RichTextEmbed failed to load content URL: \(url).")
        }
        DDLogError("Error: \(error.localizedDescription)")
    }

}
