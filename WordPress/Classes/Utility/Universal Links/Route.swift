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
