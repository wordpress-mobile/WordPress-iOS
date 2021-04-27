import Foundation

/// Helper class for creating LikeUser objects.
/// Used by PostService and CommentService when fetching likes for posts/comments.
///
@objc class LikeUserHelper: NSObject {

    @objc class func createUserFrom(remoteUser: RemoteLikeUser, context: NSManagedObjectContext) {

        guard let likeUser = NSEntityDescription.insertNewObject(forEntityName: "LikeUser", into: context) as? LikeUser else {
            return
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
    }

    private class func createPreferredBlogFrom(remotePreferredBlog: RemoteLikeUserPreferredBlog?,
                                 forUser user: LikeUser,
                                 context: NSManagedObjectContext) -> LikeUserPreferredBlog? {

        guard let remotePreferredBlog = remotePreferredBlog,
              let preferredBlog = NSEntityDescription.insertNewObject(forEntityName: "LikeUserPreferredBlog", into: context) as? LikeUserPreferredBlog else {
            return nil
        }

        preferredBlog.blogUrl = remotePreferredBlog.blogUrl
        preferredBlog.blogName = remotePreferredBlog.blogName
        preferredBlog.iconUrl = remotePreferredBlog.iconUrl
        preferredBlog.blogID = remotePreferredBlog.blogID?.int64Value ?? 0
        preferredBlog.user = user

        return preferredBlog
    }

}
