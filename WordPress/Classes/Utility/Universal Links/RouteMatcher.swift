import Foundation

/// RouterMatcher finds URL routes with paths that match a specified path, and
/// attempts to extract URL components for any placeholders present in the route.
///
class RouteMatcher {
    let routes: [Route]

    /// - parameter routes: A collection of routes to match against.
    init(routes: [Route]) {
        self.routes = routes
    }

    /// Finds routes that match the specified path. If any of the matching routes
    /// contain placeholder components, the actual values for those placeholders
    /// will be extracted, and returned in the `values` dictionary of a MatchedRoute.
    ///
    /// Example: Given a route with the path `/me/account/:username`, and a
    ///          path to match of `/me/account/alice`, a matched route will
    ///          be returned with a values dictionary containing ["username": "alice"].
    ///
    /// - parameter path: A path to match against this matcher's routes collection.
    /// - returns: A collection of MatchedRoutes whose paths match `path`.
    ///
    func routesMatching(_ path: String) -> [MatchedRoute] {
        let pathComponents = (path as NSString).pathComponents

        return routes.compactMap({ route in
            // If the paths are the same, we definitely have a match
            if route.path == path {
                return route.matched()
            }

            let routeComponents = route.components

            // Ensure the paths have the same number of components
            guard routeComponents.count == pathComponents.count else {
                return nil
            }

            guard let values = placeholderDictionary(forKeyComponents: routeComponents,
                                                     valueComponents: pathComponents) else {
                                                        return nil
            }

            return route.matched(with: values)
        })
    }

    private func isPlaceholder(_ component: String) -> Bool {
        return component.hasPrefix(":")
    }

    private func placeholderKey(for component: String) -> String {
        return String(component.dropFirst())
    }

    private func placeholderDictionary(forKeyComponents keyComponents: [String], valueComponents: [String]) -> [String: String]? {
        var values = [String: String]()

        for (keyComponent, valueComponent) in zip(keyComponents, valueComponents) {
            if isPlaceholder(keyComponent) {
                let key = placeholderKey(for: keyComponent)
                values[key] = valueComponent
            } else if keyComponent != valueComponent {
                return nil
            }
        }

        return values
    }
}

/// A route that has been detected when handling a universal link, with optional
/// values extracted from the universal link's path.
///
struct MatchedRoute: Route {
    let path: String
    let action: NavigationAction
    let values: [String: String]

    init(path: String, action: NavigationAction, values: [String: String] = [:]) {
        self.path = path
        self.action = action
        self.values = values
    }
}

extension Route {
    /// - returns: A MatchedRoute for the current path, with optional values
    ///            extracted from the resolved path.
    fileprivate func matched(with values: [String: String] = [:]) -> MatchedRoute {
        return MatchedRoute(path: path, action: action, values: values)
    }
}
