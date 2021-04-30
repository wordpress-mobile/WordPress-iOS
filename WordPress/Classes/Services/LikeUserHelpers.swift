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
        likeUser.dateLikedString = remoteUser.dateLiked ?? ""
        likeUser.dateLiked = DateUtils.date(fromISOString: likeUser.dateLikedString)
        likeUser.likedSiteID = remoteUser.likedSiteID?.int64Value ?? 0
        likeUser.likedPostID = remoteUser.likedPostID?.int64Value ?? 0
        likeUser.likedCommentID = remoteUser.likedCommentID?.int64Value ?? 0
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
