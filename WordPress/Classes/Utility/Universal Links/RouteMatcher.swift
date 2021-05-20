import Foundation

/// RouterMatcher finds URL routes with paths that match the path of a specified URL,
/// and attempts to extract URL components for any placeholders present in the route.
///
class RouteMatcher {
    let routes: [Route]

    /// - parameter routes: A collection of routes to match against.
    init(routes: [Route]) {
        self.routes = routes
    }

    /// Finds routes that match the specified URL's path. If any of the matching routes
    /// contain placeholder components, the actual values for those placeholders
    /// will be extracted, and returned in the `values` dictionary of a MatchedRoute.
    ///
    /// Example: Given a route with the path `/me/account/:username`, and a
    ///          path to match of `/me/account/alice`, a matched route will
    ///          be returned with a values dictionary containing ["username": "alice"].
    ///
    /// - parameter url: A URL to match against this matcher's routes collection.
    /// - returns: A collection of MatchedRoutes whose paths match `path`.
    ///
    func routesMatching(_ url: URL) -> [MatchedRoute] {
        let pathComponents = url.pathComponents

        return routes.compactMap({ route in
            let values = valuesDictionary(forURL: url)

            // If the paths are the same, we definitely have a match
            if route.path == url.path {
                return route.matched(with: values)
            }

            let routeComponents = route.components

            // Ensure the paths have the same number of components
            guard routeComponents.count == pathComponents.count else {
                return nil
            }

            guard let placeholderValues = placeholderDictionary(forKeyComponents: routeComponents,
                                                                valueComponents: pathComponents) else {
                                                                    return nil
            }

            let allValues = values.merging(placeholderValues,
                                           uniquingKeysWith: { (current, _) in current })

            return route.matched(with: allValues)
        })
    }

    private func valuesDictionary(forURL url: URL) -> [String: String] {
        var values: [String: String] = [
            MatchedRouteURLComponentKey.url.rawValue: url.absoluteString
        ]

        if let fragment = url.fragment {
            values[MatchedRouteURLComponentKey.fragment.rawValue] = fragment
        }

        if let source = sourceQueryItemValue(for: url) {
            values[MatchedRouteURLComponentKey.source.rawValue] = source
        }

        return values
    }

    private func sourceQueryItemValue(for url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let urlSource = components.queryItems?.first(where: { $0.name == "source" })?.value?.removingPercentEncoding else {
            return nil
        }

        return urlSource
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
    let section: DeepLinkSection?
    let source: DeepLinkSource
    let action: NavigationAction
    let shouldTrack: Bool
    let values: [String: String]

    init(from route: Route, with values: [String: String] = [:]) {
        // Allows optional overriding of source based on the input URL parameters.
        // Currently used for widget links.
        let sourceValue = values[MatchedRouteURLComponentKey.source.rawValue] ?? ""
        let source = DeepLinkSource(sourceName: sourceValue)

        self.path = route.path
        self.section = route.section
        self.source = source ?? route.source
        self.action = route.action
        self.shouldTrack = route.shouldTrack
        self.values = values
    }
}

extension Route {
    /// - returns: A MatchedRoute for the current path, with optional values
    ///            extracted from the resolved path.
    fileprivate func matched(with values: [String: String] = [:]) -> MatchedRoute {
        return MatchedRoute(from: self, with: values)
    }
}

enum MatchedRouteURLComponentKey: String {
    case fragment = "matched-route-fragment"
    case source = "matched-route-source"
    case url = "matched-route-url"
}
