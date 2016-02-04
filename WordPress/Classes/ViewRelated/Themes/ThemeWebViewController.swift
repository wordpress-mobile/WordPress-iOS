import Foundation

/// ThemeWebViewController adds support for theme page navigation
///
public class ThemeWebViewController: WPWebViewController
{
    // MARK: - Properties: must be set by creator
    
    /// The Theme whose pages will be viewed
    ///
    public var theme: Theme? {
        didSet {
            if let blog = theme?.blog {
                authToken = blog.authToken
                username = blog.usernameForSite
                password = blog.password
                wpLoginURL = NSURL(string: blog.loginUrl())
            }
        }
    }
    
    // MARK: - Navigation constants

    /// All Customize links must have "hide_close" set
    ///
    private struct Customize
    {
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
            self.url = NSURL(string: url)
        }
    }

    // MARK: - UIWebViewDelegate

    override public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if let url = request.URL, components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) {
            
            if components.path == Customize.path {
                let hideCloseItem = NSURLQueryItem(name: Customize.hideClose.name, value: Customize.hideClose.value)
                let queryItems = components.queryItems ?? []
                if !queryItems.contains(hideCloseItem) {
                    components.queryItems = queryItems + [hideCloseItem]
                    self.url = components.URL
                    
                    return false
                }
            }
        }

        return super.webView(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
    }

}
