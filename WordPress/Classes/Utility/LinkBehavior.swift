import Foundation
import WebKit

enum LinkBehavior {
    case all
    case hostOnly(URL)
    case urlOnly(URL)
    case withBaseURLOnly(String)

    func handle(navigationAction: WKNavigationAction, for webView: WKWebView) -> WKNavigationActionPolicy {
        return handle(request: navigationAction.request, with: navigationAction.navigationType)
    }

    func handle(request: URLRequest, with type: WKNavigationType) -> WKNavigationActionPolicy {
        // We only want to apply this policy for links, not for all resource loads
        guard type == .linkActivated && request.url == request.mainDocumentURL else {
            return .allow
        }

        // Should not happen, but future checks will not work if we can't check the URL
        guard let navigationURL = request.url else {
            return .allow
        }

        switch self {
        case .all:
            return .allow
        case .hostOnly(let url):
            if request.url?.host == url.host {
                return .allow
            } else {
                UIApplication.shared.open(navigationURL)
                return .cancel
            }
        case .urlOnly(let url):
            if request.url?.absoluteString == url.absoluteString {
                return .allow
            } else {
                UIApplication.shared.open(navigationURL)
                return .cancel
            }
        case .withBaseURLOnly(let baseURL):
            if request.url?.absoluteString.hasPrefix(baseURL) ?? false {
                return .allow
            } else {
                UIApplication.shared.open(navigationURL)
                return .cancel
            }
        }
    }
}
