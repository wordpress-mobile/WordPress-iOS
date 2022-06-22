import Foundation

struct QRLoginToken: Equatable {
    let token: String
    let data: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.token == rhs.token && lhs.data == rhs.data
    }
}

struct QRLoginURLParser {
    private let urlString: String

    init(urlString: String) {
        self.urlString = urlString
    }

    /// Attempts to retrieve the QR Login token information from the incoming urlString
    /// - Returns: QRLoginToken or nil if the parsing fails for any reason
    func parse() -> QRLoginToken? {
        // Early validation, making sure this is a valid URL from a valid host
        guard let url = URL(string: urlString), Self.isValidHost(url: url) else {
            return nil
        }

        // Try extracting the token URL query from the URL
        // The #qr-code-login?token=TOKEN&data=DATA fragment
        // Then try pulling the token and data from the components
        guard
            let tokenComponents = extractTokenComponents(from: url),
            let token = tokenComponents[Constants.tokenKey],
            let data = tokenComponents[Constants.dataKey]
        else {
            return nil
        }

        return QRLoginToken(token: token, data: data)
    }

    /// Validates that the input URL is coming from a valid host
    static func isValidHost(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        return host == Constants.validHost
    }

    private func extractTokenComponents(from url: URL) -> [String: String]? {
        guard let fragment = url.fragment else {
            return nil
        }

        guard let meow = URLComponents(string: fragment)?.queryItems else {
            return nil
        }

        // Map the URLQueryItem array to a dict so we can easily pull info out
        var dict: [String: String] = [:]
        meow.forEach { dict[$0.name] = $0.value }

        return dict
    }

    private struct Constants {
        static let validHost = "apps.wordpress.com"
        static let tokenKey = "token"
        static let dataKey = "data"
    }
}
