import Foundation
import CoreData


public class BlogAuthor: NSManagedObject {
    @NSManaged public var userID: NSNumber
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var primaryBlogID: NSNumber?
    @NSManaged public var avatarURL: String?
    @NSManaged public var linkedUserID: NSNumber?
    @NSManaged public var blog: Blog?
    @NSManaged public var deletedFromBlog: Bool
}
