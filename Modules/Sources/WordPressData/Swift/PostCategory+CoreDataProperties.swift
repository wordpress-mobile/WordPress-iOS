import Foundation
import CoreData

public extension PostCategory {
    @NSManaged var categoryID: NSNumber
    @NSManaged var categoryName: String
    @NSManaged var parentID: NSNumber
    @NSManaged var blog: Blog
    @NSManaged var posts: Set<Post>?
}

// MARK: - Relationship Accessors

extension PostCategory {
    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: Post)

    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: Post)

    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: NSSet)

    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: NSSet)
}
