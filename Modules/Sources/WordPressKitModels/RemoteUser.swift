import Foundation

@objcMembers public class RemoteUser: NSObject {
    public var userID: NSNumber?
    public var username: String?
    public var email: String?
    public var displayName: String?
    public var primaryBlogID: NSNumber?
    public var avatarURL: String?
    public var dateCreated: Date?
    public var emailVerified: Bool = false
    public var linkedUserID: NSNumber?
}
