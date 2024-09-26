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
                return "https://public-api.wordpress.com/connect"
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

    // MARK: - Authorization Actions

    /// Classify actions taken by the web API
    ///
    enum AuthorizeAction: Int {
        case none
        case unknown
        case request
        case verify
        case deny
    }

    static func authorizeAction(for matchURL: URL) -> AuthorizeAction {
        // Path oauth declines are handled by a redirect to a path.com URL, so check this first.
        if url(matchURL, contains: .declinePath) {
            return .deny
        }

        if !url(matchURL, contains: .authorizationPrefix) {
            return .none
        }

        if url(matchURL, contains: .requestActionItem) {
            return .request
        }

        // Check the rest of the various decline ranges
        if url(matchURL, contains: .denyActionItem) {
            return .deny
        }

        // LinkedIn
        if url(matchURL, contains: .userRefused) {
            return .deny
        }

        // Facebook and Google+
        if url(matchURL, contains: .accessDenied) {
            return .deny
        }

        // If we've made it this far and the `action=verify` query param is present then we're
        // *probably* verifying the oauth request.  There are edge cases ( :cough: tumblr :cough: )
        // where verification is declined and we get a false positive.
        if url(matchURL, contains: .verifyActionItem) {
            return .verify
        }

        // Facebook
        if url(matchURL, contains: .stateItem) && url(matchURL, contains: .codeItem) {
            return .verify
        }

        // Facebook failure
        if url(matchURL, contains: .stateItem) && url(matchURL, contains: .errorItem) {
            return .unknown
        }

        return .unknown
    }
}
