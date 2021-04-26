import CoreData

@objc(LikeUserPreferredBlog)
public class LikeUserPreferredBlog: NSManagedObject {

    static func createBlogFrom(remoteBlog: RemoteLikeUserPreferredBlog,
                               forUser user: LikeUser,
                               context: NSManagedObjectContext) -> LikeUserPreferredBlog? {

        guard let preferredBlog = NSEntityDescription.insertNewObject(forEntityName: "LikeUserPreferredBlog", into: context) as? LikeUserPreferredBlog else {
            return nil
        }

        preferredBlog.blogUrl = remoteBlog.blogUrl
        preferredBlog.blogName = remoteBlog.blogName
        preferredBlog.iconUrl = remoteBlog.iconUrl
        preferredBlog.blogID = remoteBlog.blogID?.int64Value ?? 0
        preferredBlog.user = user

        return preferredBlog
    }

}
