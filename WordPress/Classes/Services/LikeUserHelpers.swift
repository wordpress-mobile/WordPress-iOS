import Foundation
import CoreData

/// Helper class for creating LikeUser objects.
/// Used by PostService and CommentService when fetching likes for posts/comments.
///
@objc class LikeUserHelper: NSObject {

    @objc class func createOrUpdateFrom(remoteUser: RemoteLikeUser, context: NSManagedObjectContext) -> LikeUser {
        let liker = likeUser(for: remoteUser, context: context) ?? LikeUser(context: context)

        liker.userID = remoteUser.userID.int64Value
        liker.username = remoteUser.username
        liker.displayName = remoteUser.displayName
        liker.primaryBlogID = remoteUser.primaryBlogID?.int64Value ?? 0
        liker.avatarUrl = remoteUser.avatarURL
        liker.bio = remoteUser.bio ?? ""
        liker.dateLikedString = remoteUser.dateLiked ?? ""
        liker.dateLiked = DateUtils.date(fromISOString: liker.dateLikedString)
        liker.likedSiteID = remoteUser.likedSiteID?.int64Value ?? 0
        liker.likedPostID = remoteUser.likedPostID?.int64Value ?? 0
        liker.likedCommentID = remoteUser.likedCommentID?.int64Value ?? 0
        liker.dateFetched = Date()

        updatePreferredBlog(for: liker, with: remoteUser, context: context)

        return liker
    }

    class func likeUser(for remoteUser: RemoteLikeUser, context: NSManagedObjectContext) -> LikeUser? {
        let userID = remoteUser.userID ?? 0
        let siteID = remoteUser.likedSiteID ?? 0
        let postID = remoteUser.likedPostID ?? 0
        let commentID = remoteUser.likedCommentID ?? 0

        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(format: "userID = %@ AND likedSiteID = %@ AND likedPostID = %@ AND likedCommentID = %@",
                                        userID, siteID, postID, commentID)
        return try? context.fetch(request).first
    }

    /**
     Fetches a list of users from Core Data that liked the comment with the given IDs.

     @param commentID   The ID of the comment to fetch likes for.
     @param siteID      The ID of the site that contains the post.
     @param after       Filter results to likes after this Date. Optional.
     */
    class func likeUsersFor(commentID: NSNumber, siteID: NSNumber, after: Date? = nil, in context: NSManagedObjectContext) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        request.predicate = {
            if let after = after {
                // The date comparison is 'less than' because Likes are in descending order.
                return NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@ AND dateLiked < %@", siteID, commentID, after as CVarArg)
            }

            return NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@", siteID, commentID)
        }()

        request.sortDescriptors = [NSSortDescriptor(key: "dateLiked", ascending: false)]

        if let users = try? context.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

    private class func updatePreferredBlog(for user: LikeUser, with remoteUser: RemoteLikeUser, context: NSManagedObjectContext) {
        guard let remotePreferredBlog = remoteUser.preferredBlog else {
            if let existingPreferredBlog = user.preferredBlog {
                context.deleteObject(existingPreferredBlog)
                user.preferredBlog = nil
            }

            return
        }

        let preferredBlog = user.preferredBlog ?? LikeUserPreferredBlog(context: context)

        preferredBlog.blogUrl = remotePreferredBlog.blogUrl
        preferredBlog.blogName = remotePreferredBlog.blogName
        preferredBlog.iconUrl = remotePreferredBlog.iconUrl
        preferredBlog.blogID = remotePreferredBlog.blogID?.int64Value ?? 0
        preferredBlog.user = user
    }

    // Delete all LikeUsers that were last fetched at least 7 days ago.
    class func purgeStaleLikes(fromContext context: NSManagedObjectContext) {
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
