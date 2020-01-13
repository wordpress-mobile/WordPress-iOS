import Foundation
import WebKit

enum LinkBehavior {
    case all
    case hostOnly(URL)
    case urlOnly(URL)

    func handle(navigationAction: WKNavigationAction, for webView: WKWebView) -> WKNavigationActionPolicy {

        // We only want to apply this policy for links, not for all resource loads
        guard navigationAction.navigationType == .linkActivated else { return .allow }

        switch self {
        case .all:
            return .allow
        case .hostOnly(let url):
            if navigationAction.request.url?.host == url.host {
                return .allow
            } else {
                UIApplication.shared.open(navigationAction.request.url!)
                return .cancel
            }
        case .urlOnly(let url):
            if navigationAction.request.url?.absoluteString == url.absoluteString {
                return .allow
            } else {
                UIApplication.shared.open(navigationAction.request.url!)
                return .cancel
            }
        }
    }
}
