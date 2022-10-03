import Foundation

public extension Blog {
    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    @objc(lookupPostWithID:inContext:)
    func lookupPost(withID postID: NSNumber, in context: NSManagedObjectContext) -> AbstractPost? {
        try? AbstractPost.query()
            .equal(\.blog, self)
            .null(\.original)
            .equal(\.postID, postID)
            .first(in: context)
    }

    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    func lookupPost(withID postID: Int, in context: NSManagedObjectContext) -> AbstractPost? {
        lookupPost(withID: postID as NSNumber, in: context)
    }

    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    func lookupPost(withID postID: Int64, in context: NSManagedObjectContext) -> AbstractPost? {
        lookupPost(withID: postID as NSNumber, in: context)
    }
}
