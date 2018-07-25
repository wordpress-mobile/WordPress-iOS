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

    var action: NavigationAction {
        return self
    }
}

extension AppBannerRoute: NavigationAction {
    func perform(_ values: [String: String]?) {
        guard let fragmentValue = values?[MatchedRouteURLComponentKey.fragment.rawValue],
        let fragment = fragmentValue.removingPercentEncoding else {
            return
        }

        // Convert the fragment into a URL and ask the link router to handle
        // it like a normal route.
        var components = URLComponents()
        components.path = fragment

        if let url = components.url {
            // We disable tracking when passing the URL back through the router,
            // otherwise we'd be posting two stats events.
            UniversalLinkRouter.shared.handle(url: url, shouldTrack: false)
        }
    }
}
