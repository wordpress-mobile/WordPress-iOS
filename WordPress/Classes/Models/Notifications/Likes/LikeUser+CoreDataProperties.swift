import CoreData

extension LikeUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LikeUser> {
        return NSFetchRequest<LikeUser>(entityName: "LikeUser")
    }

    @NSManaged public var userID: Int64
    @NSManaged public var username: String
    @NSManaged public var displayName: String
    @NSManaged public var primaryBlogID: Int64
    @NSManaged public var avatarUrl: String
    @NSManaged public var bio: String
    @NSManaged public var dateLiked: Date
    @NSManaged public var dateLikedString: String
    @NSManaged public var likedSiteID: Int64
    @NSManaged public var likedPostID: Int64
    @NSManaged public var likedCommentID: Int64
    @NSManaged public var preferredBlog: LikeUserPreferredBlog?
    @NSManaged public var dateFetched: Date
}
