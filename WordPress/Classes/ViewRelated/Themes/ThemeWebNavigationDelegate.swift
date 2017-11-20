import Foundation
import WebKit

class ThemeWebNavigationDelegate: NSObject, WebNavigationDelegate {
    // MARK: - Navigation constants

    /// All Customize links must have "hide_close" set
    ///
    private struct Customize {
        static let path = "/wp-admin/customize.php"
        static let hideClose = (name: "hide_close", value: "true")
    }

    func shouldNavigate(request: URLRequest) -> WebNavigationPolicy {
        if let url = request.url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if components.path == Customize.path {
                let hideCloseItem = URLQueryItem(name: Customize.hideClose.name, value: Customize.hideClose.value)
                let queryItems = components.queryItems ?? []
                if !queryItems.contains(hideCloseItem) {
                    components.queryItems = queryItems + [hideCloseItem]
                    if let url = components.url {
                        return .redirect(URLRequest(url: url))
                    } else {
                        return .cancel
                    }
                }
            }
        }
        return .allow
    }
}
