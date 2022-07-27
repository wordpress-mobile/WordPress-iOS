import CoreData

extension LikeUserPreferredBlog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LikeUserPreferredBlog> {
        return NSFetchRequest<LikeUserPreferredBlog>(entityName: "LikeUserPreferredBlog")
    }

    @NSManaged public var blogUrl: String
    @NSManaged public var blogName: String
    @NSManaged public var iconUrl: String
    @NSManaged public var blogID: Int64
    @NSManaged public var user: LikeUser

}
