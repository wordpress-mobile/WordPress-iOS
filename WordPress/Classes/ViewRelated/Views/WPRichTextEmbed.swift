import Foundation

class WPRichTextEmbed : UIView, UIWebViewDelegate, WPRichTextMediaAttachment
{
    typealias successBlock = ((WPRichTextEmbed)->())


    // MARK: Properties

    var fixedHeight : CGFloat = 0.0
    var attachmentSize = CGSizeZero
    var documentSize : CGSize {
        get {
            return webView.scrollView.contentSize;
        }
    }
    var success : successBlock?
    var linkURL : NSURL?
    var contentURL : NSURL?
    var webView : UIWebView

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
        webView = UIWebView(frame: CGRectMake(0.0, 0.0, 100.0, 100.0)) // arbitrary frame

        super.init(frame: frame)

        clipsToBounds = true
        configureWebView()
    }

    required init(coder aDecoder: NSCoder) {
        if let decodedWebView = aDecoder.decodeObjectForKey("webView") as? UIWebView {
            webView = decodedWebView
        } else {
            webView = UIWebView(frame: CGRectMake(0.0, 0.0, 100.0, 100.0))
        }

        super.init(coder: aDecoder)

        configureWebView()
    }

    override func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(webView, forKey: "webView")

        super.encodeWithCoder(aCoder)
    }


    // MARK: Configuration

    func configureWebView() {
        webView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        webView.scrollView.scrollEnabled = false
        webView.scalesPageToFit = true
        webView.delegate = self
    }


    // MARK: Public Methods

    func contentSize() -> CGSize {
        if webView.superview == nil {
            return CGSizeMake(1.0, 1.0)
        }

        // embeds, unlike images, typically have no intrinsic content size that we can use to fall back on
        if (fixedHeight > 0) {
            return CGSizeMake(CGFloat(CGFLOAT_WIDTH_UNKNOWN), fixedHeight)
        }

        if !CGSizeEqualToSize(attachmentSize, CGSizeZero) {
            return attachmentSize
        }

        return documentSize
    }

    func contentRatio() -> CGFloat {
        if (fixedHeight > 0) {
            return 0.0
        }

        if !CGSizeEqualToSize(attachmentSize, CGSizeZero) {
            return attachmentSize.width / attachmentSize.height
        }

        if (!CGSizeEqualToSize(documentSize, CGSizeZero)) {
            return documentSize.width / documentSize.height
        }

        return 0.0
    }

    func loadContentURL(url: NSURL) {
        contentURL = url
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }

    func loadHTMLString(html: NSString) {
        var htmlString = String(format: "<html><head><meta name=\"viewport\" content=\"width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" /></head><body>%@</body></html>", html)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }


    // MARK: WebView delegate methods

    func webViewDidFinishLoad(webView: UIWebView) {
        // Add the webView as a subview if it hasn't been already.
        if webView.superview == nil {
            // Make sure that any viewport meta tag does not have a min scale incase we're display smaller than the device width.
            var viewport =  "var tid = setInterval( function () {" +
                "if ( document.readyState !== 'complete' ) return;" +
                "   clearInterval( tid );" +
                "   viewport = document.querySelector('meta[name=viewport]'); " +
                "   if (viewport) {" +
                "       viewport.setAttribute('content', 'width=available-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');" +
                "   }" +
                "}, 100 );"
            webView.stringByEvaluatingJavaScriptFromString(viewport);

            webView.frame = bounds
            addSubview(webView)
        }

        // Perform the callback, but only once.
        if let callback = success {
            callback(self)
        }
        success = nil
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        // TODO : Log error
        // DDLogError()
    }

}
