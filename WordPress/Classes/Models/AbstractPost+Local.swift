import Foundation

public extension AbstractPost {
    /// Count posts that have never been uploaded to the server.
    ///
    /// - Parameter context: A `NSManagedObjectContext` in which to count the posts
    /// - Returns: number of local posts in the given context.
    static func countLocalPosts(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<AbstractPost>(entityName: NSStringFromClass(AbstractPost.self))
        request.predicate = NSPredicate(format: "postID = NULL OR postID <= 0")
        return (try? context.count(for: request)) ?? 0
    }
}
