import WebKit
import WordPressShared
import WordPressUI

/// Renders the comment body with a web view. Provides the best visual experience but has the highest performance cost.
@MainActor
public final class WebCommentContentRenderer: NSObject, CommentContentRenderer {
    // MARK: Properties

    public weak var delegate: CommentContentRendererDelegate?

    public var view: UIView { webView }

    private let webView = WKWebView(frame: .zero, configuration: {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        return configuration
    }())

    /// It can't be changed at the moment, but this capability was included from the
    /// start, and this implementation continues supporting it.
    private var displaySetting = ReaderDisplaySettings.standard

    /// - warning: This has to be configured _before_ you render.
    public var tintColor: UIColor {
        get { webView.tintColor }
        set {
            webView.tintColor = newValue
            cachedHead = nil
        }
    }

    private var cachedHead: String?
    private var comment: String?

    /// A shared web view context with resources that can be reused across
    /// mutliple web view instances.
    @MainActor
    public final class Context {
        let processPool = WKProcessPool()

        public init() {}
    }

    // MARK: Methods

    public required override convenience init() {
        self.init(context: .init())
    }

    public init(context: Context) {
        super.init()

        webView.configuration.processPool = context.processPool

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        webView.backgroundColor = .clear
        webView.isOpaque = false // gets rid of the white flash upon content load in dark mode.
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.backgroundColor = .clear
    }

    public func render(comment: String) {
        self.comment = comment

        webView.loadHTMLString(formattedHTMLString(for: comment), baseURL: nil)
    }

    public func prepareForReuse() {
        comment = nil
        webView.stopLoading()
    }
}

// MARK: - WKNavigationDelegate

extension WebCommentContentRenderer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let comment else {
            return
        }
        // Wait until the HTML document finished loading.
        // This also waits for all of resources within the HTML (images, video thumbnail images) to be fully loaded.
        webView.evaluateJavaScript("document.readyState") { complete, _ in
            guard complete != nil, self.comment == comment else {
                return
            }

            // To capture the content height, the methods to use is either `document.body.scrollHeight` or `document.documentElement.scrollHeight`.
            // `document.body` does not capture margins on <body> tag, so we'll use `document.documentElement` instead.
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { [weak self] height, _ in
                guard let self, let height = height as? CGFloat else {
                    return
                }

                /// The display setting's custom size is applied through the HTML's initial-scale property
                /// in the meta tag. The `scrollHeight` value seems to return the height as if it's at 1.0 scale,
                /// so we'll need to add the custom scale into account.
                let actualHeight = round(height * self.displaySetting.size.scale)
                self.delegate?.renderer(self, asyncRenderCompletedWithHeight: actualHeight, comment: comment)
            }
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        switch navigationAction.navigationType {
        case .other:
            // allow local file requests.
            return .allow
        default:
            guard let destinationURL = navigationAction.request.url else {
                return .allow
            }
            self.delegate?.renderer(self, interactedWithURL: destinationURL)
            return .cancel
        }
    }
}

private extension WebCommentContentRenderer {
    /// Returns a formatted HTML string by loading the template for rich comment.
    ///
    /// The method will try to return cached content if possible, by detecting whether the content matches the previous content.
    /// If it's different (e.g. due to edits), it will reprocess the HTML string.
    ///
    /// - Parameter content: The content value from the `Comment` object.
    /// - Returns: Formatted HTML string to be displayed in the web view.
    ///
    func formattedHTMLString(for comment: String) -> String {
        // remove empty HTML elements from the `content`, as the content often contains empty paragraph elements which adds unnecessary padding/margin.
        // `rawContent` does not have this problem, but it's not used because `rawContent` gets rid of links (<a> tags) for mentions.
        let comment = comment
            .replacingOccurrences(of: Self.emptyElementRegexPattern, with: "", options: [.regularExpression])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        <html dir="auto">
        \(makeHead())
        <body>
            \(comment)
        </body>
        </html>
        """
    }

    static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"

    /// Returns HTML page <head> with the preconfigured styles and scripts.
    private func makeHead() -> String {
        if let cachedHead {
            return cachedHead
        }
        let head = actuallyMakeHead()
        cachedHead = head
        return head
    }

    private func actuallyMakeHead() -> String {
        let meta = "width=device-width,initial-scale=\(displaySetting.size.scale),maximum-scale=\(displaySetting.size.scale),user-scalable=no,shrink-to-fit=no"
        let styles = displaySetting.makeStyles(tintColor: webView.tintColor)
        return String(format: Self.headTemplate, meta, styles)
    }

    private static let headTemplate: String = {
        guard let fileURL = Bundle.module.url(forResource: "gutenbergCommentHeadTemplate", withExtension: "html"),
              let string = try? String(contentsOf: fileURL) else {
            assertionFailure("template missing")
            return ""
        }
        return string
    }()
}
