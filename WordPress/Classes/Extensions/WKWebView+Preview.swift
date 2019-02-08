import WebKit

/// This extension contains a couple of small hacks used in site previews
/// to hide various wpcom UI elements from webpages or prevent interaction.
///
extension WKWebView {

    func prepareWPComPreview() {
        hideWPComPreviewBanners()
        preventInteraction()
    }

    /// Hides the 'Create your website at WordPress.com' getting started bar,
    /// displayed on logged out sites, as well as the cookie widget banner.
    func hideWPComPreviewBanners() {
        let javascript = """
        document.querySelector('html').style.cssText += '; margin-top: 0 !important;';\n        document.getElementById('wpadminbar').style.display = 'none';\n
        document.getElementsByClassName("widget_eu_cookie_law_widget")[0].style += '; display: none !important;';\n
        """

        evaluateJavaScript(javascript, completionHandler: nil)
    }

    /// Prevents interaction on the current page using CSS.
    func preventInteraction() {
        let javascript = """
        document.querySelector('*').style.cssText += '; pointer-events: none; -webkit-tap-highlight-color: rgba(0,0,0,0);';\n
        """

        evaluateJavaScript(javascript, completionHandler: nil)
    }
}
