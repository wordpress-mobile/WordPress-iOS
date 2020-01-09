import AutomatticTracks
import WebKit

/// This extension provides a mechanism to request the UserAgent for WKWebViews
///
@objc
extension WKWebView {

    /// Call this method to get the user agent for the WKWebView
    ///
    @objc
    func userAgent() -> String {
        return stringByEvaluatingJavaScript(fromString: "navigator.userAgent");
    }
    
    /// Static version of the method that returns the current user agent.
    ///
    @objc
    static func userAgent() -> String {
        return WKWebView().userAgent()
    }
}
