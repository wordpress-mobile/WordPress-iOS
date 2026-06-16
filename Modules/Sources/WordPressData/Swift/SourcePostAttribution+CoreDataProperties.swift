import Foundation
import CoreData

public extension SourcePostAttribution {
    @NSManaged var permalink: String?
    @NSManaged var authorName: String?
    @NSManaged var authorURL: String?
    @NSManaged var blogName: String?
    @NSManaged var blogURL: String?
    @NSManaged var blogID: NSNumber?
    @NSManaged var postID: NSNumber?
    @NSManaged var commentCount: NSNumber?
    @NSManaged var likeCount: NSNumber?
    @NSManaged var avatarURL: String?
    @NSManaged var attributionType: String?
    @NSManaged var post: ReaderPost
}
