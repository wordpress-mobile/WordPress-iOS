import WebKit

/// Renders the comment body with a web view. Provides the best visual experience but has the highest performance cost.
///
class WebCommentContentRenderer: NSObject, CommentContentRenderer {

    // MARK: Properties

    weak var delegate: CommentContentRendererDelegate?

    private let comment: Comment

    private let webView = WKWebView(frame: .zero)

    /// Used to determine whether the cache is still valid or not.
    private var commentContentCache: String? = nil

    /// Caches the HTML content, to be reused when the orientation changed.
    private var htmlContentCache: String? = nil

    // MARK: Methods

    required init(comment: Comment) {
        self.comment = comment
    }

    func render() -> UIView {
        // Do not reload if the content doesn't change.
        if let contentCache = commentContentCache, contentCache == comment.content {
            return webView
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.isOpaque = false // gets rid of the white flash upon content load in dark mode.

        webView.loadHTMLString(formattedHTMLString(for: comment.content), baseURL: Self.resourceURL)

        return webView
    }

    func matchesContent(from comment: Comment) -> Bool {
        // if content cache is still nil, then the comment hasn't been rendered yet.
        guard let contentCache = commentContentCache else {
            return false
        }

        return contentCache == comment.content
    }
}

// MARK: - WKNavigationDelegate

extension WebCommentContentRenderer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait until the HTML document finished loading.
        // This also waits for all of resources within the HTML (images, video thumbnail images) to be fully loaded.
        webView.evaluateJavaScript("document.readyState") { complete, _ in
            guard complete != nil else {
                return
            }

            // To capture the content height, the methods to use is either `document.body.scrollHeight` or `document.documentElement.scrollHeight`.
            // `document.body` does not capture margins on <body> tag, so we'll use `document.documentElement` instead.
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { height, _ in
                guard let height = height as? CGFloat else {
                    return
                }

                // reset the webview to opaque again so the scroll indicator is visible.
                webView.isOpaque = true
                self.delegate?.renderer(self, asyncRenderCompletedWithHeight: height)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .other:
            // allow local file requests.
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
            guard let destinationURL = navigationAction.request.url else {
                return
            }

            self.delegate?.renderer(self, interactedWithURL: destinationURL)
        }
    }
}

// MARK: - Private Methods

private extension WebCommentContentRenderer {
    struct Constants {
        static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"
    }

    /// Used for the web view's `baseURL`, to reference any local files (i.e. CSS) linked from the HTML.
    static let resourceURL: URL? = {
        Bundle.main.resourceURL
    }()

    /// Cache the HTML template format. We only need read the template once.
    static let htmlTemplateFormat: String? = {
        guard let templatePath = Bundle.main.path(forResource: "richCommentTemplate", ofType: "html"),
              let templateString = try? String(contentsOfFile: templatePath) else {
            return nil
        }

        return templateString
    }()

    /// Returns a formatted HTML string by loading the template for rich comment.
    ///
    /// The method will try to return cached content if possible, by detecting whether the content matches the previous content.
    /// If it's different (e.g. due to edits), it will reprocess the HTML string.
    ///
    /// - Parameter content: The content value from the `Comment` object.
    /// - Returns: Formatted HTML string to be displayed in the web view.
    ///
    func formattedHTMLString(for content: String) -> String {
        // return the previous HTML string if the comment content is unchanged.
        if let previousCommentContent = commentContentCache,
           let previousHTMLString = htmlContentCache,
           previousCommentContent == content {
            return previousHTMLString
        }

        // otherwise: sanitize the content, cache it, and then return it.
        guard let htmlTemplateFormat = Self.htmlTemplateFormat else {
            DDLogError("WebCommentContentRenderer: Failed to load HTML template format for comment content.")
            return String()
        }

        // remove empty HTML elements from the `content`, as the content often contains empty paragraph elements which adds unnecessary padding/margin.
        // `rawContent` does not have this problem, but it's not used because `rawContent` gets rid of links (<a> tags) for mentions.
        let htmlContent = String(format: htmlTemplateFormat, content
                                    .replacingOccurrences(of: Constants.emptyElementRegexPattern, with: String(), options: [.regularExpression])
                                    .trimmingCharacters(in: .whitespacesAndNewlines))

        // cache the contents.
        commentContentCache = content
        htmlContentCache = htmlContent

        return htmlContent
    }
}
