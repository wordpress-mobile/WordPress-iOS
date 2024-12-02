@preconcurrency import WebKit
import WordPressShared

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

    private let displaySetting: ReaderDisplaySetting

    // MARK: Methods

    required convenience init(comment: Comment) {
        self.init(comment: comment, displaySetting: .standard)
    }

    required init(comment: Comment, displaySetting: ReaderDisplaySetting) {
        self.comment = comment
        self.displaySetting = displaySetting
        super.init()

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
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.userContentController.add(self, name: "eventHandler")
    }

    func render() -> UIView {
        // Do not reload if the content doesn't change.
        if let contentCache = commentContentCache, contentCache == comment.content {
            return webView
        }

        webView.loadHTMLString(formattedHTMLString(for: comment.content), baseURL: Bundle.wordPressSharedBundle.bundleURL)

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
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { [weak self] height, _ in
                guard let self,
                      let height = height as? CGFloat else {
                    return
                }

                /// The display setting's custom size is applied through the HTML's initial-scale property
                /// in the meta tag. The `scrollHeight` value seems to return the height as if it's at 1.0 scale,
                /// so we'll need to add the custom scale into account.
                let actualHeight = round(height * self.displaySetting.size.scale)
                self.delegate?.renderer(self, asyncRenderCompletedWithHeight: actualHeight)
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

// MARK: - WKScriptMessageHandler

extension WebCommentContentRenderer: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let event = ReaderWebView.EventMessage(rawValue: body)?.analyticEvent else {
            return
        }
        WPAnalytics.track(event)
    }

}

// MARK: - Private Methods

private extension WebCommentContentRenderer {
    struct Constants {
        static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"

        static let highlightColor = UIColor(light: UIAppColor.primary, dark: UIAppColor.primary(.shade30))

        static let mentionBackgroundColor: UIColor = {
            var darkColor = UIAppColor.primary(.shade90)

            if AppConfiguration.isWordPress {
                darkColor = darkColor.withAlphaComponent(0.5)
            }

            return UIColor(light: UIAppColor.primary(.shade0), dark: darkColor)
        }()
    }

    /// Used for the web view's `baseURL`, to reference any local files (i.e. CSS) linked from the HTML.
    static let resourceURL: URL? = {
        Bundle.wordPressSharedBundle.bundleURL
    }()

    var textColor: UIColor {
        ReaderDisplaySetting.customizationEnabled ? displaySetting.color.foreground : .label
    }

    var mentionBackgroundColor: UIColor {
        guard ReaderDisplaySetting.customizationEnabled else {
            return Constants.mentionBackgroundColor
        }

        return displaySetting.color == .system ? Constants.mentionBackgroundColor : displaySetting.color.secondaryBackground
    }

    var linkColor: UIColor {
        guard ReaderDisplaySetting.customizationEnabled else {
            return Constants.highlightColor
        }

        return displaySetting.color == .system ? Constants.highlightColor : displaySetting.color.foreground
    }

    var secondaryBackgroundColor: UIColor {
        guard ReaderDisplaySetting.customizationEnabled else {
            return .secondarySystemBackground
        }
        return displaySetting.color.secondaryBackground
    }

    /// Cache the HTML template format. We only need read the template once.
    var htmlTemplateFormat: String? {
        guard let templatePath = Bundle.main.path(forResource: "richCommentTemplate", ofType: "html"),
              let templateStringFormat = try? String(contentsOfFile: templatePath) else {
            return nil
        }

        return String(format: templateStringFormat,
                      metaContents.joined(separator: ", "),
                      cssStyles,
                      "%@")
    }

    var metaContents: [String] {
        [
            "width=device-width",
            "initial-scale=\(displaySetting.size.scale)",
            "maximum-scale=\(displaySetting.size.scale)",
            "user-scalable=no",
            "shrink-to-fit=no"
        ]
    }

    /// We'll need to load `richCommentStyle.css` from the main bundle and inject it as a string,
    /// because the web view needs to be loaded with the WordPressShared bundle to gain access to custom fonts.
    var cssStyles: String {
        guard let cssURL = Bundle.main.url(forResource: "richCommentStyle", withExtension: "css"),
              let cssContent = try? String(contentsOf: cssURL) else {
            return String()
        }
        return cssContent.appending(overrideStyles)
    }

    /// Additional styles based on system or custom theme.
    var overrideStyles: String {
        """
        /* Basic style variables */
        :root {
            --text-font: \(displaySetting.font.cssString);

            /* link styling */
            --link-font-weight: \(displaySetting.color == .system ? "inherit" : "600");
            --link-text-decoration: \(displaySetting.color == .system ? "inherit" : "underline");
        }

        /* Color overrides for light mode */
        @media(prefers-color-scheme: light) {
            \(cssColors(interfaceStyle: .light))
        }

        /* Color overrides for dark mode */
        @media(prefers-color-scheme: dark) {
            \(cssColors(interfaceStyle: .dark))
        }
        """
    }

    /// CSS color definitions that matches the current color theme.
    /// - Parameter interfaceStyle: The current `UIUserInterfaceStyle` value.
    /// - Returns: A string of CSS colors to be injected.
    private func cssColors(interfaceStyle: UIUserInterfaceStyle) -> String {
        let trait = UITraitCollection(userInterfaceStyle: interfaceStyle)

        return """
        :root {
            --text-color: \(textColor.color(for: trait).cssRGBAString());
            --text-secondary-color: \(displaySetting.color.secondaryForeground.color(for: trait).cssRGBAString());
            --link-color: \(linkColor.color(for: trait).cssRGBAString());
            --mention-background-color: \(mentionBackgroundColor.color(for: trait).cssRGBAString());
            --background-secondary-color: \(secondaryBackgroundColor.color(for: trait).cssRGBAString());
            --border-color: \(displaySetting.color.border.color(for: trait).cssRGBAString());
        }
        """
    }

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
        guard let htmlTemplateFormat else {
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

private extension UIColor {
    func cssRGBAString(customAlpha: CGFloat? = nil) -> String {
        let red = Int(rgbaComponents.red * 255)
        let green = Int(rgbaComponents.green * 255)
        let blue = Int(rgbaComponents.blue * 255)
        let alpha = {
            guard let customAlpha, customAlpha <= 1.0 else {
                return rgbaComponents.alpha
            }
            return customAlpha
        }()

        return "rgba(\(red), \(green), \(blue), \(alpha))"
    }
}
