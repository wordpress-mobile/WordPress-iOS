import Foundation

/// Helper Enum that specifies all of the available Gravatar Image Ratings
/// TODO: Convert into a pure Swift String Enum. It's done this way to maintain ObjC Compatibility
///
@available(*, deprecated, message: "Use `Rating` from the Gravatar iOS SDK. See: https://github.com/Automattic/Gravatar-SDK-iOS.")
@objc
public enum GravatarRatings: Int {
    case g
    case pg
    case r
    case x
    case `default`

    func stringValue() -> String {
        switch self {
        case .default:
            fallthrough
        case .g:
            return "g"
        case .pg:
            return "pg"
        case .r:
            return "r"
        case .x:
            return "x"
        }
    }
}

/// Helper Enum that specifies some of the options for default images
/// To see all available options, visit : https://en.gravatar.com/site/implement/images/
///
@available(*, deprecated, message: "Use `DefaultAvatarOption` from the Gravatar iOS SDK. See: https://github.com/Automattic/Gravatar-SDK-iOS.")
public enum GravatarDefaultImage: String {
    case fileNotFound = "404"
    case mp
    case identicon
}

@available(*, deprecated, message: "Use `AvatarURL` from the Gravatar iOS SDK. See: https://github.com/Automattic/Gravatar-SDK-iOS")
public struct Gravatar {
    fileprivate struct Defaults {
        static let scheme = "https"
        static let host = "secure.gravatar.com"
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
        static let baseURL = "https://gravatar.com/avatar"
        static let imageSize = 80
    }

    public let canonicalURL: URL

    public func urlWithSize(_ size: Int, defaultImage: GravatarDefaultImage? = nil) -> URL {
        var components = URLComponents(url: canonicalURL, resolvingAgainstBaseURL: false)!
        components.query = "s=\(size)&d=\(defaultImage?.rawValue ?? GravatarDefaultImage.fileNotFound.rawValue)"
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

    /// Returns the Gravatar URL, for a given email, with the specified size + rating.
    ///
    /// - Parameters:
    ///     - email: the user's email
    ///     - size: required download size
    ///     - rating: image rating filtering
    ///
    /// - Returns: Gravatar's URL
    ///
    public static func gravatarUrl(for email: String,
                                   defaultImage: GravatarDefaultImage? = nil,
                                   size: Int? = nil,
                                   rating: GravatarRatings = .default) -> URL? {
        let hash = gravatarHash(of: email)
        let targetURL = String(format: "%@/%@?d=%@&s=%d&r=%@",
                               Defaults.baseURL,
                               hash,
                               defaultImage?.rawValue ?? GravatarDefaultImage.fileNotFound.rawValue,
                               size ?? Defaults.imageSize,
                               rating.stringValue())
        return URL(string: targetURL)
    }

    /// Returns the gravatar hash of an email
    ///
    /// - Parameter email: the email associated with the gravatar
    /// - Returns: hashed email
    ///
    /// This really ought to be in a different place, like Gravatar.swift, but there's
    /// lots of duplication around gravatars -nh
    private static func gravatarHash(of email: String) -> String {
        return email
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .sha256Hash()
    }
}

@available(*, deprecated, message: "Usage of the deprecated type: Gravatar.")
extension Gravatar: Equatable {}

@available(*, deprecated, message: "Usage of the deprecated type: Gravatar.")
public func ==(lhs: Gravatar, rhs: Gravatar) -> Bool {
    return lhs.canonicalURL == rhs.canonicalURL
}

@available(*, deprecated, message: "Usage of the deprecated type: Gravatar.")
public extension Gravatar {
    @available(*, deprecated, message: "Usage of the deprecated type: Gravatar.")
    init?(_ url: URL) {
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
