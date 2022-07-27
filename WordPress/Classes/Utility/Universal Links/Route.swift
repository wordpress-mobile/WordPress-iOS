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
    var section: DeepLinkSection? { get }
    var source: DeepLinkSource { get }
    var action: NavigationAction { get }
    var shouldTrack: Bool { get }
}

extension Route {
    // Default routes to handling links rather than other source types
    var source: DeepLinkSource {
        return .link
    }

    // By default, we'll track all routes, but certain routes can override this.
    // Routes like banner and email routes may not want to track their original
    // link, but will instead just track any redirect that they contain.
    var shouldTrack: Bool {
        return true
    }
}

protocol NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter)
}

extension NavigationAction {
    /// Fails the navigation and attempts to bounce the user back to Safari
    /// - returns: True if we attempted to launch the URL, otherwise false
    @discardableResult
    func failAndBounce(_ values: [String: String]) -> Bool {
        guard let urlString = values[MatchedRouteURLComponentKey.url.rawValue],
            let url = URL(string: urlString) else {
                return false
        }

        let noOptions: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        UIApplication.shared.open(url, options: noOptions, completionHandler: nil)
        return true
    }
}

struct FailureNavigationAction: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
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

// MARK: - Tracking

/// Where did the deep link originate?
///
enum DeepLinkSource: Equatable {
    case link
    case banner
    case email(campaign: String)
    case widget
    case inApp(presenter: UIViewController?)

    init?(sourceName: String) {
        switch sourceName {
        // We only care about widgets right now, but we could
        // add others in the future if necessary.
        case "widget":
            self = .widget
        default:
            return nil
        }
    }

    var isInternal: Bool {
        switch self {
        case .inApp:
            return true
        default:
            return false
        }
    }

    var trackingInfo: String? {
        switch self {
        case .email(let campaign):
            return campaign
        default:
            return nil
        }
    }
}

/// Which broad section of the app is being linked to?
///
enum DeepLinkSection: String {
    case editor
    case me
    case mySite = "my_site"
    case notifications
    case reader
    case siteCreation = "site_creation"
    case stats
}
