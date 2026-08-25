import Foundation
import CoreData
import WordPressData
import WordPressKit

/// Helper class for creating LikeUser objects.
/// Used by PostService and CommentService when fetching likes for posts/comments.
///
@objc class LikeUserHelper: NSObject {

    @objc class func createOrUpdateFrom(remoteUser: RemoteLikeUser, context: NSManagedObjectContext) -> LikeUser {
        let liker = likeUser(for: remoteUser, context: context) ?? LikeUser(context: context)

        liker.userID = remoteUser.userID?.int64Value ?? 0
        liker.username = remoteUser.username ?? ""
        liker.displayName = remoteUser.displayName ?? ""
        liker.primaryBlogID = remoteUser.primaryBlogID?.int64Value ?? 0
        liker.avatarUrl = remoteUser.avatarURL ?? ""
        liker.bio = remoteUser.bio ?? ""
        liker.dateLikedString = remoteUser.dateLiked ?? ""
        liker.dateLiked = Date.dateFromServerDate(liker.dateLikedString) ?? .now
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
        request.predicate = NSPredicate(
            format: "userID = %@ AND likedSiteID = %@ AND likedPostID = %@ AND likedCommentID = %@",
            userID,
            siteID,
            postID,
            commentID
        )
        return try? context.fetch(request).first
    }

    /**
     Fetches a list of users from Core Data that liked the comment with the given IDs.

     @param commentID   The ID of the comment to fetch likes for.
     @param siteID      The ID of the site that contains the post.
     @param after       Filter results to likes after this Date. Optional.
     */
    class func likeUsersFor(
        commentID: NSNumber,
        siteID: NSNumber,
        after: Date? = nil,
        in context: NSManagedObjectContext
    ) -> [LikeUser] {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>

        request.predicate = {
            if let after {
                // The date comparison is 'less than' because Likes are in descending order.
                return NSPredicate(
                    format: "likedSiteID = %@ AND likedCommentID = %@ AND dateLiked < %@",
                    siteID,
                    commentID,
                    after as CVarArg
                )
            }

            return NSPredicate(format: "likedSiteID = %@ AND likedCommentID = %@", siteID, commentID)
        }()

        request.sortDescriptors = [NSSortDescriptor(key: "dateLiked", ascending: false)]

        if let users = try? context.fetch(request) {
            return users
        }

        return [LikeUser]()
    }

    private class func updatePreferredBlog(
        for user: LikeUser,
        with remoteUser: RemoteLikeUser,
        context: NSManagedObjectContext
    ) {
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

/// A liker fetched by the new Stats screens, carrying only the fields that
/// fetch provides. See `LikeUserHelper.upsert(seeds:siteID:postID:in:)`.
struct LikeUserSeed: Sendable {
    let userID: Int64
    let displayName: String
    let username: String
    let avatarUrl: String
    let dateLikedString: String
}

extension LikeUserHelper {
    /// Merges likers fetched by Post Stats into the shared likes cache so the
    /// Likes list screen can seed itself from cache instead of starting empty.
    ///
    /// Unlike the fetch path built on `createOrUpdateFrom(remoteUser:context:)`,
    /// this never deletes other rows for the post: the caller holds only the
    /// first page of likers, and purging here could wipe a fuller previously
    /// cached list. Fields the seed does not carry (bio, preferred blog,
    /// primary blog) are left untouched on existing rows so a richer earlier
    /// fetch is not degraded.
    class func upsert(seeds: [LikeUserSeed], siteID: Int64, postID: Int64, in context: NSManagedObjectContext) {
        for seed in seeds {
            let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
            request.predicate = NSPredicate(
                format: "userID = %@ AND likedSiteID = %@ AND likedPostID = %@ AND likedCommentID = 0",
                NSNumber(value: seed.userID),
                NSNumber(value: siteID),
                NSNumber(value: postID)
            )
            let existing = try? context.fetch(request).first

            let liker = existing ?? LikeUser(context: context)
            if existing == nil {
                // New rows need the seed-less attributes initialized.
                liker.bio = ""
                liker.primaryBlogID = 0
            }
            liker.userID = seed.userID
            liker.displayName = seed.displayName
            liker.username = seed.username
            liker.avatarUrl = seed.avatarUrl
            liker.dateLikedString = seed.dateLikedString
            liker.dateLiked = Date.dateFromServerDate(seed.dateLikedString) ?? .now
            liker.likedSiteID = siteID
            liker.likedPostID = postID
            liker.likedCommentID = 0
            liker.dateFetched = Date()
        }
    }

    /// Removes every cached post liker for the given post.
    ///
    /// Used to seed a confirmed zero-like result: when Post Stats reports a post
    /// has no likes, clearing the cache keeps the Likes list from showing stale
    /// likers under a "0 likes" title. Comment likes (`likedCommentID != 0`) are
    /// untouched.
    class func deleteLikes(forPost postID: Int64, siteID: Int64, in context: NSManagedObjectContext) {
        let request = LikeUser.fetchRequest() as NSFetchRequest<LikeUser>
        request.predicate = NSPredicate(
            format: "likedSiteID = %@ AND likedPostID = %@ AND likedCommentID = 0",
            NSNumber(value: siteID),
            NSNumber(value: postID)
        )

        do {
            let users = try context.fetch(request)
            users.forEach { context.delete($0) }
        } catch {
            DDLogError("Error fetching post Like Users to delete: \(error)")
        }
    }
}
