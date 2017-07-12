import Foundation
import WordPressShared

// MARK: - Defines all of the peroperties a Person may have
//
public protocol RemotePerson {
    /// Properties
    ///
    var ID: Int { get }
    var username: String { get }
    var firstName: String? { get }
    var lastName: String? { get }
    var displayName: String { get }
    var role: Role { get }
    var siteID: Int { get }
    var linkedUserID: Int { get }
    var avatarURL: URL? { get }
    var isSuperAdmin: Bool { get }
    var fullName: String { get }

    /// Static Properties
    ///
    static var kind: PersonKind { get }

    /// Initializers
    ///
    init(ID: Int,
         username: String,
         firstName: String?,
         lastName: String?,
         displayName: String,
         role: Role,
         siteID: Int,
         linkedUserID: Int,
         avatarURL: URL?,
         isSuperAdmin: Bool)
}

// MARK: - Specifies all of the Roles a Person may have
//
public enum Role: String, Comparable, Equatable, CustomStringConvertible {
    case SuperAdmin     = "super-admin"
    case Admin          = "administrator"
    case Editor         = "editor"
    case Author         = "author"
    case Contributor    = "contributor"
    case Subscriber     = "subscriber"
    case Follower       = "follower"
    case Viewer         = "viewer"
    case Unsupported    = "unsupported"
}

// MARK: - Specifies all of the possible Person Types that might exist.
//
public enum PersonKind: Int {
    case user       = 0
    case follower   = 1
    case viewer     = 2
}

// MARK: - Defines a Blog's User
//
public struct User: RemotePerson {
    public let ID: Int
    public let username: String
    public let firstName: String?
    public let lastName: String?
    public let displayName: String
    public let role: Role
    public let siteID: Int
    public let linkedUserID: Int
    public let avatarURL: URL?
    public let isSuperAdmin: Bool
    public static let kind = PersonKind.user
}

// MARK: - Defines a Blog's Follower
//
public struct Follower: RemotePerson {
    public let ID: Int
    public let username: String
    public let firstName: String?
    public let lastName: String?
    public let displayName: String
    public let role: Role
    public let siteID: Int
    public let linkedUserID: Int
    public let avatarURL: URL?
    public let isSuperAdmin: Bool
    public static let kind = PersonKind.follower
}

// MARK: - Defines a Blog's Viewer
//
public struct Viewer: RemotePerson {
    public let ID: Int
    public let username: String
    public let firstName: String?
    public let lastName: String?
    public let displayName: String
    public let role: Role
    public let siteID: Int
    public let linkedUserID: Int
    public let avatarURL: URL?
    public let isSuperAdmin: Bool
    public static let kind = PersonKind.viewer
}

// MARK: - Extensions
//
public extension RemotePerson {
    var fullName: String {
        let first = firstName ?? String()
        let last = lastName ?? String()
        let separator = (first.isEmpty == false && last.isEmpty == false) ? " " : ""

        return "\(first)\(separator)\(last)"
    }
}

public extension Role {
    init(string: String) {
        guard let parsedRole = Role(rawValue: string) else {
            self = .Unsupported
            return
        }
        
        self = parsedRole
    }
    
    var description: String {
        return rawValue
    }
    
    var remoteValue: String {
        // Note: Incoming Hack
        // ====
        //
        // Apologies about this. When a site is Private, the *Viewer* doesn't really exist, but instead,
        // it's treated, backend side, as a follower.
        //
        switch self {
        case .Viewer:
            return Role.Follower.rawValue
        default:
            return rawValue
        }
    }
}

// MARK: - Operator Overloading
//
public func ==<T: RemotePerson>(lhs: T, rhs: T) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.username == rhs.username
        && lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.displayName == rhs.displayName
        && lhs.role == rhs.role
        && lhs.siteID == rhs.siteID
        && lhs.linkedUserID == rhs.linkedUserID
        && lhs.avatarURL == rhs.avatarURL
        && lhs.isSuperAdmin == rhs.isSuperAdmin
        && type(of: lhs) == type(of: rhs)
}

public func ==(lhs: Role, rhs: Role) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func <(lhs: Role, rhs: Role) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
