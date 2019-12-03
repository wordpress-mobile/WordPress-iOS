import Foundation

struct LoggingURLRedactor {

    static func redactedURL(_ url: URL) -> URL {

        if isAuthURL(url) {
            return redactParameter(named: "token", in: url)
        }

        return url
    }

    private static func redactParameter(named key: String, in url: URL) -> URL {

        // If we can't process this URL, just send back whatever came in
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        if var queryItem = components.queryItems?.first(where: { $0.name == key }) {

            guard let ix = components.queryItems?.firstIndex(of: queryItem) else {
                return url
            }

            queryItem.value = "redacted"
            components.queryItems?[ix] = queryItem
        }

        // If the components are somehow unable to be turned back into a URL,
        // just send back the original.
        guard let redactedURL = components.url else {
            return url
        }

        return redactedURL
    }

    private static func isAuthURL(_ url: URL) -> Bool {

        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let parameters = components.queryItems,
            parameters.contains(where: { $0.name == "token" })
        else {
            return false
        }

        let auth_schemes = ["wordpress", "wpinternal", "wordpress-oauth-v2", "wpdebug", "wpalpha"]

        // If the scheme doesn't match, this definitely isn't an auth URL
        guard let scheme = url.scheme, auth_schemes.contains(scheme) else {
            return false
        }

        return true
    }
}
