import Foundation

public struct Gravatar {
    fileprivate struct Defaults {
        static let scheme = "https"
        static let host = "secure.gravatar.com"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    public let canonicalURL: URL

    public func urlWithSize(_ size: Int) -> URL {
        var components = URLComponents(url: canonicalURL, resolvingAgainstBaseURL: false)!
        components.query = "s=\(size)&d=404"
        return components.url!
    }

    public static func isGravatarURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let host = components.host, host.hasSuffix(".gravatar.com") else {
                return false
        }

        guard url.path.hasPrefix("/avatar/") else {
                return false
        }

        return true
    }
}

extension Gravatar: Equatable {}

public func ==(lhs: Gravatar, rhs: Gravatar) -> Bool {
    return lhs.canonicalURL == rhs.canonicalURL
}

public extension Gravatar {
    public init?(_ url: URL) {
        guard Gravatar.isGravatarURL(url) else {
            return nil
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.scheme = Defaults.scheme
        components.host = Defaults.host
        components.query = nil

        // Treat unknown@gravatar.com as a nil url
        guard url.lastPathComponent != Defaults.unknownHash else {
            return nil
        }

        guard let sanitizedURL = components.url else {
            return nil
        }

        self.canonicalURL = sanitizedURL
    }
}
