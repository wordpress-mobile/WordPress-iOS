import AutomatticTracks
import WebKit

/// This extension provides a mechanism to request the UserAgent for WKWebViews
///
@objc
extension WKWebView {
    static let userAgentKey = "_userAgent"

    /// Call this method to get the user agent for the WKWebView
    ///
    @objc
    func userAgent() -> String {
        guard let userAgent = value(forKey: WKWebView.userAgentKey) as? String,
            userAgent.count > 0 else {
                WordPressAppDelegate.crashLogging?.logMessage(
                    "This method for retrieveing the user agent seems to be no longer working.  We need to figure out an alternative.",
                    properties: [:],
                    level: .error)
                return ""
        }

        return userAgent
    }

    /// Static version of the method that returns the current user agent.
    ///
    @objc
    static func userAgent() -> String {
        return WKWebView().userAgent()
    }
}
