import Foundation

public extension Blog {
    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    @objc(lookupPostWithID:inContext:)
    func lookupPost(withID postID: NSNumber, in context: NSManagedObjectContext) -> AbstractPost? {
        lookupPost(withID: postID.int64Value, in: context)
    }

    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    func lookupPost(withID postID: Int64, in context: NSManagedObjectContext) -> AbstractPost? {
        let request = NSFetchRequest<AbstractPost>(entityName: NSStringFromClass(AbstractPost.self))
        request.predicate = NSPredicate(format: "blog = %@ AND original = NULL AND postID = %@", self, NSNumber(value: postID))
        return (try? context.fetch(request))?.first
    }
}
