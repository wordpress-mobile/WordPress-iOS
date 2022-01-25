import Foundation

/// Used to detect whether a URL matches a particular Publicize authorization success or failure route.
enum PublicizeConnectionURLMatcher {
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
    private var queryItem: URLQueryItem? {
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
    private var matchString: String? {
        switch self {
        case .declinePath:
            return "/decline"
        case .authorizationPrefix:
            return "https://public-api.wordpress.com/connect/"
        default:
            return nil
        }
    }

    /// @return True if the url matches the current authorization component
    ///
    func containedIn(_ url: URL) -> Bool {
        if let _ = queryItem {
            return queryItemContainedIn(url)
        }

        return stringContainedIn(url)
    }

    // Checks to see if the current QueryItem is present in the specified URL
    private func queryItemContainedIn(_ url: URL) -> Bool {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
              let queryItem = queryItem else {
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

    // Checks to see if the current matchString is present in the specified URL
    private func stringContainedIn(_ url: URL) -> Bool {
        guard let matchString = matchString else {
            return false
        }

        switch self {
        case .declinePath:
            return url.path.contains(matchString)
        case .authorizationPrefix:
            return url.absoluteString.hasPrefix(matchString)
        default:
            return url.absoluteString.contains(matchString)
        }
    }
}
