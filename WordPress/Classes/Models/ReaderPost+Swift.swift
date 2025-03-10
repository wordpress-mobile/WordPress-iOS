import Foundation
import WordPressUI

extension ReaderPost {

    /// - note: this is a workaround for https://github.com/wordpress-mobile/WordPress-iOS/issues/18975 and
    /// https://github.com/wordpress-mobile/WordPress-iOS/issues/20953. This code
    /// makes sure that you see the "Follow Conversation" button on P2s
    /// but not if you have "Emails me all comments" option enabled, which
    /// matches the behavior on the web.
    var canActuallySubscribeToComments: Bool {
        if canSubscribeComments {
            return true
        }
        if isP2Type() {
            return !((topic as? ReaderSiteTopic)?.emailSubscription?.sendComments ?? false)
        }
        return false
    }

    func getSiteIconURL(size: Int) -> URL? {
        SiteIconViewModel.makeReaderSiteIconURL(iconURL: siteIconURL, siteID: siteID?.intValue, size: CGSize(width: size, height: size))
    }

    /// Find cached comment with given ID.
    ///
    /// - Parameter id: The comment id
    /// - Returns: The `Comment` object associated with the given id, or `nil` if none is found.
    @objc
    func comment(withID id: NSNumber) -> Comment? {
        comment(withID: id.int32Value)
    }

    /// Find cached comment with given ID.
    ///
    /// - Parameter id: The comment id
    /// - Returns: The `Comment` object associated with the given id, or `nil` if none is found.
    func comment(withID id: Int32) -> Comment? {
        return (comments as? Set<Comment>)?.first { $0.commentID == id }
    }

    /// Get a cached site's ReaderPost with the specified ID.
    ///
    /// - Parameter postID: ID of the post.
    /// - Parameter siteID: ID of the site the post belongs to.
    /// - Returns: the matching `ReaderPost`, or `nil` if none is found.
    static func lookup(withID postID: NSNumber, forSiteWithID siteID: NSNumber, in context: NSManagedObjectContext) throws -> ReaderPost? {
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "postID = %@ AND siteID = %@", postID, siteID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Get a cached site's ReaderPost with the specified ID.
    ///
    /// - Parameter postID: ID of the post.
    /// - Parameter siteID: ID of the site the post belongs to.
    /// - Returns: the matching `ReaderPost`, or `nil` if none is found.
    @objc(lookupWithID:forSiteWithID:inContext:)
    static func objc_lookup(withID postID: NSNumber, forSiteWithID siteID: NSNumber, in context: NSManagedObjectContext) -> ReaderPost? {
        try? lookup(withID: postID, forSiteWithID: siteID, in: context)
    }

}
