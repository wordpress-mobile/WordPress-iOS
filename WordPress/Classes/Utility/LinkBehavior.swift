import Foundation
import WebKit

enum LinkBehavior {
    case all
    case hostOnly(URL)
    case urlOnly(URL)

    func handle(navigationAction: WKNavigationAction, for webView: WKWebView) -> WKNavigationActionPolicy {

        // We only want to apply this policy for links, not for all resource loads
        guard navigationAction.navigationType == .linkActivated && navigationAction.request.url == navigationAction.request.mainDocumentURL else {
            return .allow
        }

        // Should not happen, but future checks will not work if we can't check the URL
        guard let navigationURL = navigationAction.request.url else {
            return .allow
        }

        switch self {
        case .all:
            return .allow
        case .hostOnly(let url):
            if navigationAction.request.url?.host == url.host {
                return .allow
            } else {
                UIApplication.shared.open(navigationURL)
                return .cancel
            }
        case .urlOnly(let url):
            if navigationAction.request.url?.absoluteString == url.absoluteString {
                return .allow
            } else {
                UIApplication.shared.open(navigationURL)
                return .cancel
            }
        }
    }
}
