import Foundation
import CoreData

extension BasePost {

    // MARK: - Attributes

    @NSManaged public var postID: NSNumber?
    @NSManaged public var authorID: NSNumber?
    @NSManaged public var author: String?
    @NSManaged public var authorAvatarURL: String?
    @NSManaged public var date_created_gmt: Date?
    @NSManaged public var postTitle: String?
    @NSManaged public var content: String?
    @NSManaged public var password: String?
    @NSManaged public var permaLink: String?
    @NSManaged public var mt_excerpt: String?
    @NSManaged public var wp_slug: String?
    @NSManaged public var suggested_slug: String?
    @NSManaged public var remoteStatusNumber: NSNumber?
    @NSManaged public var pathForDisplayImage: String?

    // MARK: - Relationships

    @NSManaged public var comments: Set<Comment>?
}

// MARK: - Generated Accessors for comments

extension BasePost {
    @objc(addCommentsObject:)
    @NSManaged public func addCommentsObject(_ value: Comment)

    @objc(removeCommentsObject:)
    @NSManaged public func removeCommentsObject(_ value: Comment)

    @objc(addComments:)
    @NSManaged public func addComments(_ values: Set<Comment>)

    @objc(removeComments:)
    @NSManaged public func removeComments(_ values: Set<Comment>)
}
