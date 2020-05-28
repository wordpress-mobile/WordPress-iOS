import UIKit

/// A WKWebView that renders post content with styles applied
///
class ReaderWebView: WKWebView {

    /// Make the webview transparent
    ///
    override func awakeFromNib() {
        isOpaque = false
        backgroundColor = .clear
    }

    /// Loads a HTML content into the webview and apply styles
    ///
    @discardableResult
    override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        let content = """
        <!DOCTYPE html><html><head><meta charset='UTF-8' />
        <title>Reader Post</title>
        <meta name='viewport' content='initial-scale=1, maximum-scale=1.0, user-scalable=no'>
        <style>
        \(cssColors())
        \(cssStyles())
        </style>
        </head><body>
        \(string)
        </body></html>
        """

        return super.loadHTMLString(content, baseURL: Bundle.wordPressSharedBundle.bundleURL)
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

    /// Maps app colors to CSS colors to be applied in the webview
    ///
    private func cssColors() -> String {
        if #available(iOS 13, *) {
            return """
                @media (prefers-color-scheme: dark) {
                    \(mappedCSSColors(.dark))
                }

                @media (prefers-color-scheme: light) {
                    \(mappedCSSColors(.light))
                }
            """
        }

        return lightCSSColors()
    }

    /// If iOS 13, returns light and dark colors
    ///
    @available(iOS 13, *)
    private func mappedCSSColors(_ style: UIUserInterfaceStyle) -> String {
        let trait = UITraitCollection(userInterfaceStyle: style)
        return """
            :root {
              --main-txt-color: #\(UIColor.text.color(for: trait).hexString() ?? "");
              --main-grey-extra-light: #\(UIColor.listIcon.color(for: trait).hexString() ?? "");
              --main-grey-medium-dark: #\(UIColor.textSubtle.color(for: trait).hexString() ?? "");
              --main-link-color: #\(UIColor.primary.color(for: trait).hexString() ?? "");
              --main-link-active-color: #\(UIColor.primaryDark.color(for: trait).hexString() ?? "")'
            }
        """
    }

    /// If iOS 12 or below, returns only light colors
    ///
    private func lightCSSColors() -> String {
        return """
            :root {
              --main-txt-color: #\(UIColor.text.hexString() ?? "");
              --main-grey-extra-light: #\(UIColor.listIcon.hexString() ?? "");
              --main-grey-medium-dark: #\(UIColor.textSubtle.hexString() ?? "");
              --main-link-color: #\(UIColor.primary.hexString() ?? "");
              --main-link-active-color: #\(UIColor.primaryDark.hexString() ?? "")'
            }
        """
    }
}
