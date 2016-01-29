import Foundation

/// ThemeWebViewController adds support for theme page navigation
///
public class ThemeWebViewController: WPWebViewController
{
    // MARK: - Initializer
    
    /// Preferred initializer for ThemeWebViewController
    ///
    /// - Parameters:
    ///     - url: The URL to navigate to when presented
    ///
    public convenience init(url: String) {
        self.init(nibName: "WPWebViewController", bundle: nil)
        
        self.url = NSURL(string: url)
    }

}
