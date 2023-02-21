import Foundation

extension ReaderPost {

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
    /// - Parameter siteID: ID of th site the post belongs to.
    /// - Returns: the matching `ReaderPost`.
    static func lookup(withID postID: NSNumber, forSiteWithID siteID: NSNumber, in context: NSManagedObjectContext) throws -> ReaderPost? {
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "postID = %@ AND siteID = %@", postID, siteID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Get a cached site's ReaderPost with the specified ID.
    ///
    /// - Parameter postID: ID of the post.
    /// - Parameter siteID: ID of th site the post belongs to.
    /// - Returns: the matching `ReaderPost`.
    @objc(lookupWithID:forSiteWithID:inContext:)
    static func objc_lookup(withID postID: NSNumber, forSiteWithID siteID: NSNumber, in context: NSManagedObjectContext) -> ReaderPost? {
        try? lookup(withID: postID, forSiteWithID: siteID, in: context)
    }

}
