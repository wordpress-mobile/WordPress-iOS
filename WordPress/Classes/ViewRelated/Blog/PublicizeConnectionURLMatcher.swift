import Foundation

/// Used to detect whether a URL matches a particular Publicize authorization success or failure route.
struct PublicizeConnectionURLMatcher {
    enum MatchComponent {
        case verifyActionItem
        case denyActionItem
        case requestActionItem
        case stateItem
        case codeItem
        case errorItem

        case authorizationPrefix
        case declinePath
        case accessDenied

        // Special handling for the inconsistent way that services respond to a user's choice to decline
        // oauth authorization.
        // Right now we have no clear way to know if Tumblr fails.  This is something we should try
        // fixing moving forward.
        // Path does not set the action param or call the callback. It forwards to its own URL ending in /decline.
        case userRefused

        // In most cases, we attempt to find a matching URL by checking for a specific URL component
        fileprivate var queryItem: URLQueryItem? {
            switch self {
            case .verifyActionItem:
                return URLQueryItem(name: "action", value: "verify")
            case .denyActionItem:
                return URLQueryItem(name: "action", value: "deny")
            case .requestActionItem:
                return URLQueryItem(name: "action", value: "request")
            case .accessDenied:
                return URLQueryItem(name: "error", value: "access_denied")
            case .stateItem:
                return URLQueryItem(name: "state", value: nil)
            case .codeItem:
                return URLQueryItem(name: "code", value: nil)
            case .errorItem:
                return URLQueryItem(name: "error", value: nil)
            case .userRefused:
                return URLQueryItem(name: "oauth_problem", value: "user_refused")
            default:
                return nil
            }
        }

        // In a handful of cases, we're just looking for a substring or prefix in the URL
        fileprivate var matchString: String? {
            switch self {
            case .declinePath:
                return "/decline"
            case .authorizationPrefix:
                return "https://public-api.wordpress.com/connect/"
            default:
                return nil
            }
        }
    }

    /// @return True if the url matches the current authorization component
    ///
    static func url(_ url: URL, contains matchComponent: MatchComponent) -> Bool {
        if let queryItem = matchComponent.queryItem {
            return self.url(url, contains: queryItem)
        }

        if let matchString = matchComponent.matchString {
            switch matchComponent {
            case .declinePath:
                return url.path.contains(matchString)
            case .authorizationPrefix:
                return url.absoluteString.hasPrefix(matchString)
            default:
                return url.absoluteString.contains(matchString)
            }
        }

        return false
    }

    // Checks to see if the current QueryItem is present in the specified URL
    private static func url(_ url: URL, contains queryItem: URLQueryItem) -> Bool {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
            return false
        }

        return queryItems.contains(where: { urlItem in
            var result = urlItem.name == queryItem.name

            if let value = queryItem.value {
                result = result && (urlItem.value == value)
            }

            return result
        })
    }
}
