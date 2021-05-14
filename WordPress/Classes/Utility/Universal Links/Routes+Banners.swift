import Foundation

/// Routes to handle WordPress.com app banner "Open in app" links.
/// Banner routes always begin https://apps.wordpress.com/get and can contain
/// an optional fragment to route to a specific part of the app. The fragment
/// will be treated like any other route. The fragment
/// can contain additional components to route more specifically:
///
///   * /get#post
///   * /get#post/discover.wordpress.com
///
struct AppBannerRoute: Route {
    let path = "/get"
    let section: DeepLinkSection? = nil
    let source: DeepLinkSource = .banner
    let shouldTrack: Bool = false

    var action: NavigationAction {
        return self
    }
}

extension AppBannerRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        guard let fragmentValue = values[MatchedRouteURLComponentKey.fragment.rawValue],
            let fragment = fragmentValue.removingPercentEncoding else {
                return
        }

        // Convert the fragment into a URL and ask the link router to handle
        // it like a normal route.
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wordpress.com"
        components.path = fragment

        if let url = components.url {
            router.handle(url: url, shouldTrack: true, source: .banner)
        }
    }
}
