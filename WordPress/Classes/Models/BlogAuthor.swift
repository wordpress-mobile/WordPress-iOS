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
    @NSManaged public var blogs: NSSet?
}


extension BlogAuthor {
    @objc(addBlogsObject:)
    @NSManaged public func addToBlogs(_ value: Blog)

    @objc(removeBlogsObject:)
    @NSManaged public func removeFromBlogs(_ value: Blog)

    @objc(addBlogs:)
    @NSManaged public func addToBlogs(_ values: NSSet)

    @objc(removeBlogs:)
    @NSManaged public func removeFromBlogs(_ values: NSSet)
}
