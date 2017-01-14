import Foundation

/// ThemeWebViewController adds support for theme page navigation
///
open class ThemeWebViewController: WPWebViewController {
    // MARK: - Properties: must be set by creator

    /// The Theme whose pages will be viewed
    ///
    open var theme: Theme? {
        didSet {
            if let blog = theme?.blog {
                authToken = blog.authToken
                username = blog.usernameForSite
                password = blog.password
                wpLoginURL = URL(string: blog.loginUrl())
            }
        }
    }

    // MARK: - Navigation constants

    /// All Customize links must have "hide_close" set
    ///
    fileprivate struct Customize {
        static let path = "/wp-admin/customize.php"
        static let hideClose = (name: "hide_close", value: "true")
    }

    // MARK: - Initializer

    /// Preferred initializer for ThemeWebViewController
    ///
    /// - Parameters:
    ///     - theme: The Theme whose pages will be viewed
    ///     - url:   The URL to navigate to when presented
    ///
    public convenience init(theme: Theme, url: String) {
        self.init(nibName: "WPWebViewController", bundle: nil)

        defer {
            self.theme = theme
            self.url = URL(string: url)
        }
    }

    // MARK: - UIWebViewDelegate

    override open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        if let url = request.url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {

            if components.path == Customize.path {
                let hideCloseItem = URLQueryItem(name: Customize.hideClose.name, value: Customize.hideClose.value)
                let queryItems = components.queryItems ?? []
                if !queryItems.contains(hideCloseItem) {
                    components.queryItems = queryItems + [hideCloseItem]
                    self.url = components.url

                    return false
                }
            }
        }

        return super.webView(webView, shouldStartLoadWith: request, navigationType: navigationType)
    }

}
