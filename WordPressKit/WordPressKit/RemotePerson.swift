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
    var role: String { get }
    var siteID: Int { get }
    var linkedUserID: Int { get }
    var avatarURL: URL? { get }
    var isSuperAdmin: Bool { get }
    var fullName: String { get }

    ///  Static Properties
    ///
    static var kind: PersonKind { get }

    /// Initializers
    ///
    init(ID: Int,
         username: String,
         firstName: String?,
         lastName: String?,
         displayName: String,
         role: String,
         siteID: Int,
         linkedUserID: Int,
         avatarURL: URL?,
         isSuperAdmin: Bool)
}

// MARK: - Specifies all of the Roles a Person may have
//
public struct RemoteRole {
    public let slug: String
    public let name: String

    public init(slug: String, name: String) {
        self.slug = slug
        self.name = name
    }
}

extension RemoteRole {
    public static let viewer = RemoteRole(slug: "follower", name: NSLocalizedString("Viewer", comment: "User role badge"))
    public static let follower = RemoteRole(slug: "follower", name: NSLocalizedString("Follower", comment: "User role badge"))
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
    public let role: String
    public let siteID: Int
    public let linkedUserID: Int
    public let avatarURL: URL?
    public let isSuperAdmin: Bool
    public static let kind = PersonKind.user
    
    public init(ID: Int,
         username: String,
         firstName: String?,
         lastName: String?,
         displayName: String,
         role: String,
         siteID: Int,
         linkedUserID: Int,
         avatarURL: URL?,
         isSuperAdmin: Bool) {
        self.ID = ID
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.role = role
        self.siteID = siteID
        self.linkedUserID = linkedUserID
        self.avatarURL = avatarURL
        self.isSuperAdmin = isSuperAdmin
    }
}

// MARK: - Defines a Blog's Follower
//
public struct Follower: RemotePerson {
    public let ID: Int
    public let username: String
    public let firstName: String?
    public let lastName: String?
    public let displayName: String
    public let role: String
    public let siteID: Int
    public let linkedUserID: Int
    public let avatarURL: URL?
    public let isSuperAdmin: Bool
    public static let kind = PersonKind.follower
    
    public init(ID: Int,
                username: String,
                firstName: String?,
                lastName: String?,
                displayName: String,
                role: String,
                siteID: Int,
                linkedUserID: Int,
                avatarURL: URL?,
                isSuperAdmin: Bool) {
        self.ID = ID
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.role = role
        self.siteID = siteID
        self.linkedUserID = linkedUserID
        self.avatarURL = avatarURL
        self.isSuperAdmin = isSuperAdmin
    }
}

// MARK: - Defines a Blog's Viewer
//
public struct Viewer: RemotePerson {
    public let ID: Int
    public let username: String
    public let firstName: String?
    public let lastName: String?
    public let displayName: String
    public let role: String
    public let siteID: Int
    public let linkedUserID: Int
    public let avatarURL: URL?
    public let isSuperAdmin: Bool
    public static let kind = PersonKind.viewer
    
    public init(ID: Int,
                username: String,
                firstName: String?,
                lastName: String?,
                displayName: String,
                role: String,
                siteID: Int,
                linkedUserID: Int,
                avatarURL: URL?,
                isSuperAdmin: Bool) {
        self.ID = ID
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.role = role
        self.siteID = siteID
        self.linkedUserID = linkedUserID
        self.avatarURL = avatarURL
        self.isSuperAdmin = isSuperAdmin
    }
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
