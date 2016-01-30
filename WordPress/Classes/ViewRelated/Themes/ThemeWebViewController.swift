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

}
