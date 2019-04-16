import Foundation
import CoreData


extension TopViewedAuthorStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopViewedAuthorStatsRecordValue> {
        return NSFetchRequest<TopViewedAuthorStatsRecordValue>(entityName: "TopViewedAuthorStatsRecordValue")
    }

    @NSManaged public var name: String?
    @NSManaged public var avatarURLString: String?
    @NSManaged public var viewsCount: Int64
    @NSManaged public var posts: NSOrderedSet?

}

// MARK: Generated accessors for posts
extension TopViewedAuthorStatsRecordValue {

    @objc(insertObject:inPostsAtIndex:)
    @NSManaged public func insertIntoPosts(_ value: TopViewedPostStatsRecordValue, at idx: Int)

    @objc(removeObjectFromPostsAtIndex:)
    @NSManaged public func removeFromPosts(at idx: Int)

    @objc(insertPosts:atIndexes:)
    @NSManaged public func insertIntoPosts(_ values: [TopViewedPostStatsRecordValue], at indexes: NSIndexSet)

    @objc(removePostsAtIndexes:)
    @NSManaged public func removeFromPosts(at indexes: NSIndexSet)

    @objc(replaceObjectInPostsAtIndex:withObject:)
    @NSManaged public func replacePosts(at idx: Int, with value: TopViewedPostStatsRecordValue)

    @objc(replacePostsAtIndexes:withPosts:)
    @NSManaged public func replacePosts(at indexes: NSIndexSet, with values: [TopViewedPostStatsRecordValue])

    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: TopViewedPostStatsRecordValue)

    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: TopViewedPostStatsRecordValue)

    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: NSOrderedSet)

    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: NSOrderedSet)

}
