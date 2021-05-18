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
        likeUser.primaryBlogID = remoteUser.primaryBlogID?.int64Value ?? 0
        likeUser.avatarUrl = remoteUser.avatarURL
        likeUser.bio = remoteUser.bio ?? ""
        likeUser.dateLikedString = remoteUser.dateLiked ?? ""
        likeUser.dateLiked = DateUtils.date(fromISOString: likeUser.dateLikedString)
        likeUser.likedSiteID = remoteUser.likedSiteID?.int64Value ?? 0
        likeUser.likedPostID = remoteUser.likedPostID?.int64Value ?? 0
        likeUser.likedCommentID = remoteUser.likedCommentID?.int64Value ?? 0
        likeUser.preferredBlog = createPreferredBlogFrom(remotePreferredBlog: remoteUser.preferredBlog, forUser: likeUser, context: context)
        likeUser.dateFetched = Date()
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

    class func purgeStaleLikes() {
        let derivedContext = ContextManager.shared.newDerivedContext()

        derivedContext.perform {
            purgeStaleLikes(fromContext: derivedContext)
            ContextManager.shared.save(derivedContext)
        }
    }

    // Delete all LikeUsers that were last fetched at least 7 days ago.
    private class func purgeStaleLikes(fromContext context: NSManagedObjectContext) {
        guard let staleDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            DDLogError("Error creating date to purge stale Likes.")
            return
        }

        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "dateFetched <= %@", staleDate as CVarArg)

        do {
            let users = try context.fetch(request)
            users.forEach { context.delete($0) }
        } catch {
            DDLogError("Error fetching Like Users: \(error)")
        }
    }

}
