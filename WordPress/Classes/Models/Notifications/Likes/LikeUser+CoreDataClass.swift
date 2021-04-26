import CoreData

@objc(LikeUser)
public class LikeUser: NSManagedObject {

    static func createUserFrom(remoteUser: RemoteLikeUser, context: NSManagedObjectContext) -> LikeUser? {

        guard let likeUser = NSEntityDescription.insertNewObject(forEntityName: "LikeUser", into: context) as? LikeUser else {
            return nil
        }

        likeUser.userID = remoteUser.userID.int64Value
        likeUser.username = remoteUser.username
        likeUser.displayName = remoteUser.displayName
        likeUser.primaryBlogID = remoteUser.primaryBlogID.int64Value
        likeUser.avatarUrl = remoteUser.avatarURL
        likeUser.bio = remoteUser.bio ?? ""
        likeUser.dateLikesString = remoteUser.dateLiked ?? ""
        likeUser.dateLiked = DateUtils.date(fromISOString: likeUser.dateLikesString)
        likeUser.preferredBlog = createPreferredBlogFrom(remotePreferredBlog: remoteUser.preferredBlog, forUser: likeUser, context: context)

        return likeUser
    }

    static func createPreferredBlogFrom(remotePreferredBlog: RemoteLikeUserPreferredBlog?,
                                        forUser user: LikeUser,
                                        context: NSManagedObjectContext) -> LikeUserPreferredBlog? {

        guard let remotePreferredBlog = remotePreferredBlog else {
            return nil
        }

        return LikeUserPreferredBlog.createBlogFrom(remoteBlog: remotePreferredBlog, forUser: user, context: context)
    }
}
