import Foundation

/// A universal link route, used to encapsulate a URL path and action
/// A path can contain placeholder components, which can later be extracted
/// from an actual URL path by the RouteMatcher. Placeholder components should
/// be written by preceding an item with a single colon character. For example:
///
/// Path: /me/account/:username
///
protocol Route {
    var path: String { get }
    var action: NavigationAction { get }
}

protocol NavigationAction {
    func perform(_ values: [String: String]?)
}

extension NavigationAction {
    /// Fails the navigation and attempts to bounce the user back to Safari
    /// - returns: True if we attempted to launch the URL, otherwise false
    @discardableResult
    func failAndBounce(_ values: [String: String]?) -> Bool {
        guard let urlString = values?[MatchedRouteURLComponentKey.url.rawValue],
            let url = URL(string: urlString) else {
                return false
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }
}

struct FailureNavigationAction: NavigationAction {
    func perform(_ values: [String: String]?) {
        // This navigation action exists only to fail navigations
    }

    /// Convenience method to allow us to bounce a URL that hasn't been
    /// matched to a route and converted into a values dictionary.
    func failAndBounce(_ url: URL?) {
        if let url = url {
            failAndBounce([MatchedRouteURLComponentKey.url.rawValue: url.absoluteString])
        }
    }
}

// MARK: - Route helper methods

extension Route {
    /// Returns the path components of a route's path.
    var components: [String] {
        return (path as NSString).pathComponents
    }

    func isEqual(to route: Route) -> Bool {
        return path == route.path
    }
}
