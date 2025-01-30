import WebKit
import WordPressShared
import WordPressUI

/// Renders the comment body with a web view. Provides the best visual experience but has the highest performance cost.
@MainActor
public final class WebCommentContentRenderer: NSObject, CommentContentRenderer {
    // MARK: Properties

    public weak var delegate: CommentContentRendererDelegate?

    private let webView = WKWebView(frame: .zero)

    private var comment: String?

    private var displaySetting = ReaderDisplaySetting.standard

    // MARK: Methods

    public required override init() {
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
    }

    public func render(comment: String) -> UIView {
        guard self.comment != comment else {
            return webView // Already rendering this comment
        }
        self.comment = comment

        webView.loadHTMLString(formattedHTMLString(for: comment), baseURL: Bundle.wordPressSharedBundle.bundleURL)

        return webView
    }
}

// MARK: - WKNavigationDelegate

extension WebCommentContentRenderer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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

// MARK: - Private Methods

private extension WebCommentContentRenderer {
    struct Constants {
        static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"
    }

    /// Used for the web view's `baseURL`, to reference any local files (i.e. CSS) linked from the HTML.
    static let resourceURL: URL? = {
        Bundle.wordPressSharedBundle.bundleURL
    }()

    var textColor: UIColor {
        displaySetting.color.foreground
    }

    // TODO: (kean) do we want  displaySetting.color == .system?
    var mentionBackgroundColor: UIColor {
//        displaySetting.color == .system ? Constants.mentionBackgroundColor :
        displaySetting.color.secondaryBackground
    }

    var linkColor: UIColor {
//        displaySetting.color == .system ? Constants.highlightColor :
        displaySetting.color.foreground
    }

    var secondaryBackgroundColor: UIColor {
        guard ReaderDisplaySetting.customizationEnabled else {
            return .secondarySystemBackground
        }
        return displaySetting.color.secondaryBackground
    }

    /// Cache the HTML template format. We only need read the template once.
    var htmlTemplateFormat: String {
        guard let templatePath = Bundle.module.path(forResource: "richCommentTemplate", ofType: "html"),
              let templateStringFormat = try? String(contentsOfFile: templatePath) else {
            assertionFailure("template missing")
            return ""
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
        guard let cssURL = Bundle.module.url(forResource: "richCommentStyle", withExtension: "css"),
              let cssContent = try? String(contentsOf: cssURL) else {
            assertionFailure("css missing")
            return ""
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
            --text-color: \(textColor.color(for: trait).cssHex);
            --text-secondary-color: \(displaySetting.color.secondaryForeground.color(for: trait).cssHex);
            --link-color: \(linkColor.color(for: trait).cssHex);
            --mention-background-color: \(mentionBackgroundColor.color(for: trait).cssHex);
            --background-secondary-color: \(secondaryBackgroundColor.color(for: trait).cssHex);
            --border-color: \(displaySetting.color.border.color(for: trait).cssHex);
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
        // remove empty HTML elements from the `content`, as the content often contains empty paragraph elements which adds unnecessary padding/margin.
        // `rawContent` does not have this problem, but it's not used because `rawContent` gets rid of links (<a> tags) for mentions.
        let htmlContent = String(format: htmlTemplateFormat, content
            .replacingOccurrences(of: Constants.emptyElementRegexPattern, with: String(), options: [.regularExpression])
            .trimmingCharacters(in: .whitespacesAndNewlines))
        return htmlContent
    }
}

private extension UIColor {
    var cssHex: String {
        "#\(hexStringWithAlpha)"
    }
}
