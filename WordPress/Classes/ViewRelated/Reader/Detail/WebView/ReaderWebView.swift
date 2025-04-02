import UIKit
import ColorStudio
import WordPressReader
import WordPressShared
import WordPressUI
import WebKit

/// A WKWebView that renders post content with styles applied
///
class ReaderWebView: WKWebView {

    /// HTML elements that will load only after the text has appeared
    /// From: https://www.w3schools.com/tags/att_src.asp
    private let elements = ["audio", "embed", "iframe", "img", "input", "script", "source", "track", "video"]

    let jsToRemoveSrcSet = "document.querySelectorAll('img, img-placeholder').forEach((el) => {el.removeAttribute('srcset')})"

    var postURL: URL? = nil

    var isP2 = false

    var displaySetting: ReaderDisplaySettings = .standard

    deinit {
        print("here")
    }

    /// Make the webview transparent
    ///
    override func awakeFromNib() {
        super.awakeFromNib()

        isOpaque = false
        backgroundColor = .clear
        if #available(iOS 16.4, *) {
            isInspectable = true
        }

        // - warning: It retains the handler. It can't be `self`.
        configuration.userContentController.add(ReaderWebViewMessageHandler(), name: "eventHandler")
    }

    /// Loads a HTML content into the webview and apply styles
    ///
    func loadHTMLString(_ string: String) {
        // If the user is offline, we remove the srcset from all images
        // This is because only the image inside the src tag is previously saved
        let additionalJavaScript = ReachabilityUtils.isInternetReachable() ? "" : jsToRemoveSrcSet

        let content = formattedContent(addPlaceholder(string), additionalJavaScript: additionalJavaScript)

        super.loadHTMLString(content, baseURL: Bundle.wordPressSharedBundle.bundleURL)
    }

    /// Given a HTML content, returns it formatted.
    /// Ie.: Including tags, CSS, JS, etc.
    ///
    func formattedContent(_ content: String, additionalJavaScript: String = "") -> String {
        return """
        <!DOCTYPE html><html><head><meta charset='UTF-8' />
        <title>Reader Post</title>
        <meta name='viewport' content='initial-scale=\(displaySetting.size.scale), maximum-scale=\(displaySetting.size.scale), user-scalable=no'>
        <link rel="stylesheet" type="text/css" href="\(ReaderCSS().address)">
        <style>
        \(cssColors())
        \(cssStyles())
        \(p2Styles())
        \(overrideStyles())
        </style>
        </head><body class="reader-full-post reader-full-post__story-content">
        \(content)
        </body>
        <script>
            document.addEventListener('DOMContentLoaded', function(event) {
                \(additionalJavaScript)
                // Remove autoplay to avoid media autoplaying
                document.querySelectorAll('video-placeholder, audio-placeholder').forEach((el) => {el.removeAttribute('autoplay')})

                // Replaces the bundle URL with the post URL for each "blank" anchor tag (<a href="#anchor"></a>).
                // this fixes an issue where tapping on one would return a file url with the anchor attached to it
                let baseURL = "\(Bundle.wordPressSharedBundle.bundleURL)"
                let postURL = "\(postURL?.absoluteString ?? "")"

                if(postURL.length > 0){
                    let anchors = document.querySelectorAll('a')

                    anchors.forEach(function(elem){
                      // Ignore any regular links that don't have hashes
                      if(!elem.hash || elem.hash.length < 0) {
                        return
                      }

                      let href = elem.href;

                      // Skip any links that aren't the base URL
                      if(href.substr(0, baseURL.length) != baseURL){
                        return
                      }

                      elem.href = postURL + elem.hash;
                    });
                }
            })
            function debounce(fn, timeout) {
                let timer;
                return () => {
                    clearTimeout(timer);
                    timer = setTimeout(fn, timeout);
                }
            }
            const postEvent = (event) => window.webkit.messageHandlers.eventHandler.postMessage(event);
            const textHighlighted = debounce(
                () => postEvent("articleTextHighlighted"),
                1000
            );
            document.addEventListener('selectionchange', function(event) {
                const selection = document.getSelection().toString();
                if (selection.length > 0) {
                    textHighlighted();
                }
            });
            document.addEventListener('copy', event => postEvent("articleTextCopied"));
        </script>
        </html>
        """
    }

    /// Tell the webview to load all media
    /// You want to use this method only after the webview has appearead (after a didFinish, for example)
    func loadMedia() {
        evaluateJavaScript("""
            var elements = ["\(elements.joined(separator: "\",\""))"]

            elements.forEach((element) => {
                document.querySelectorAll(`${element}-placeholder`).forEach((el) => {
                    var regex = new RegExp(`${element}-placeholder`, "g")
                    el.outerHTML = el.outerHTML.replace(regex, element)
                })
            })

            // Make all images tappable
            // Exception for images in Stories, which have their own link structure
            // and images that already have a link
            document.querySelectorAll('img:not(.wp-story-image)').forEach((el) => {
                if (el.parentNode.nodeName.toLowerCase() !== 'a') {
                    el.outerHTML = `<a href="${el.src}">${el.outerHTML}</a>`;
                }
            })

            // Only display images after they have fully loaded, to have a native feel
            document.querySelectorAll('img').forEach((el) => {
                var img = new Image();
                img.addEventListener('load', () => { el.style.opacity = "1" }, false);
                img.src = el.currentSrc;
                el.src = img.src;
            })

            // Load all embeds
            const embedsToLookFor = {
                'blockquote[class^="instagram-"]': 'https://www.instagram.com/embed.js',
                'blockquote[class^="twitter-"], a[class^="twitter-"]': 'https://platform.twitter.com/widgets.js',
                'fb\\\\:post, [class^=fb-]': 'https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v2.2',
                '[class^=tumblr-]': 'https://assets.tumblr.com/post.js',
                '.embed-reddit': 'https://embed.redditmedia.com/widgets/platform.js',
                '.embed-tiktok': 'https://www.tiktok.com/embed.js',
            };

            Object.keys(embedsToLookFor).forEach((key) => {
              if (document.querySelectorAll(key).length > 0) {
                var s = document.createElement( 'script' );
                s.setAttribute( 'src', embedsToLookFor[key] );
                document.body.appendChild( s );
              }
            })

        """, completionHandler: nil)
    }

    /// Change all occurences of elements to change it's HTML tag to "element-placeholder"
    /// Ie.: img -> img-placeholder
    /// This will make the text to appear fast, so the user can start reading
    ///
    private func addPlaceholder(_ htmlContent: String) -> String {
        var content = htmlContent

        elements.forEach { content = content.replacingMatches(of: "<\($0)", with: "<\($0)-placeholder") }

        return content
    }

    /// Returns the content of reader.css
    ///
    private func cssStyles() -> String {
        guard let cssURL = Bundle.main.url(forResource: "reader", withExtension: "css") else {
            return ""
        }

        let cssContent = try? String(contentsOf: cssURL)
        return cssContent ?? ""
    }

    /// Enforce a width for emojis on P2
    private func p2Styles() -> String {
        guard isP2 else {
            return ""
        }

        return """
        img.emoji {
            width: 1em;
        }
        """
    }

    private func overrideStyles() -> String {
        /// Some context: We are fetching the CSS file from a remote endpoint, but we store a local `reader.css` file
        /// to override some styles for mobile-specific purposes.
        ///
        /// The `reader.css` forces the text to be displayed in Noto, but this method overrides it back to the
        /// user-preferred font.
        return """
            body.reader-full-post.reader-full-post__story-content {
                font: -apple-system-body !important;
                font-family: \(displaySetting.font.cssString) !important;
            }

            /* link styling */
            a {
                font-weight: \(displaySetting.color == .system ? "inherit" : "600");
                text-decoration: underline;
            }
        """
    }

    /// Maps app colors to CSS colors to be applied in the webview
    ///
    private func cssColors() -> String {
        if displaySetting.color.adaptsToInterfaceStyle {
            return """
                @media (prefers-color-scheme: dark) {
                    \(mappedCSSColors(.dark))
                }

                @media (prefers-color-scheme: light) {
                    \(mappedCSSColors(.light))
                }
            """
        }

        // for other color themes not adapting to interface, it doesn't matter what interface style we pass here
        // because the colors are fixed.
        return mappedCSSColors(.light)
    }

    private func mappedCSSColors(_ style: UIUserInterfaceStyle) -> String {
        let trait = UITraitCollection(userInterfaceStyle: style)
        return """
            :root {
              --color-text: #\(displaySetting.color.foreground.color(for: trait).hexStringWithAlpha);
              --color-neutral-0: #\(neutralColor(shade: .shade0, trait: trait).hexStringWithAlpha);
              --color-neutral-5: #\(neutralColor(shade: .shade5, trait: trait).hexStringWithAlpha);
              --color-neutral-10: #\(neutralColor(shade: .shade10, trait: trait).hexStringWithAlpha);
              --color-neutral-40: #\(neutralColor(shade: .shade40, trait: trait).hexStringWithAlpha);
              --color-neutral-50: #\(neutralColor(shade: .shade50, trait: trait).hexStringWithAlpha);
              --color-neutral-70: #\(neutralColor(shade: .shade70, trait: trait).hexStringWithAlpha);
              --main-link-color: #\(linkColor(for: trait).hexStringWithAlpha);
              --main-link-active-color: #\(activeLinkColor(for: trait).hexStringWithAlpha);
            }
        """
    }

    /// Returns the requested neutral color based on the current color theme.
    /// Note that the previous color values were preserved for the `.system` color theme.
    ///
    /// - Parameters:
    ///   - shade: `MurielColorShade` enum.
    ///   - trait: The trait collection for the color.
    /// - Returns: `UIColor`
    func neutralColor(shade: ColorStudioShade, trait: UITraitCollection) -> UIColor {
        let color: UIColor = {
            switch shade {
            case .shade0:
                if displaySetting.color == .system {
                    return .tertiarySystemGroupedBackground
                }
                return displaySetting.color.foreground.withAlphaComponent(0.1)
            case .shade5:
                if displaySetting.color == .system {
                    return UIColor(light: UIAppColor.gray(.shade5), dark: UIAppColor.gray(.shade80))
                }
                return displaySetting.color.border
            case .shade10:
                if displaySetting.color == .system {
                    return UIColor(light: UIAppColor.gray(.shade10), dark: UIAppColor.gray(.shade30))
                }
                return displaySetting.color.border
            case .shade40:
                if displaySetting.color == .system {
                    return UIColor(light: UIAppColor.gray(.shade40), dark: UIAppColor.gray(.shade20))
                }
                return displaySetting.color.secondaryForeground
            case .shade50:
                return displaySetting.color.secondaryForeground
            default:
                return displaySetting.color.foreground
            }
        }()

        return color.color(for: trait)
    }

    func linkColor(for trait: UITraitCollection) -> UIColor {
        let color = displaySetting.color == .system ? UIAppColor.blue : displaySetting.color.foreground
        return color.color(for: trait)
    }

    func activeLinkColor(for trait: UITraitCollection) -> UIColor {
        let color = displaySetting.color == .system ? UIAppColor.blue(.shade30) : displaySetting.color.secondaryForeground
        return color.color(for: trait)
    }
}

final class ReaderWebViewMessageHandler: NSObject, WKScriptMessageHandler {
    enum EventMessage: String {
        case articleTextHighlighted
        case articleTextCopied

        // Comment events are located in `richCommentTemplate.html`
        case commentTextHighlighted
        case commentTextCopied

        var analyticEvent: WPAnalyticsEvent {
            switch self {
            case .articleTextHighlighted:
                return .readerArticleTextHighlighted
            case .articleTextCopied:
                return .readerArticleTextCopied
            case .commentTextHighlighted:
                return .readerCommentTextHighlighted
            case .commentTextCopied:
                return .readerCommentTextCopied
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let event = EventMessage(rawValue: body)?.analyticEvent else {
            return
        }
        WPAnalytics.track(event)
    }
}
