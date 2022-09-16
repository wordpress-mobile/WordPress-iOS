import Foundation

extension AbstractPost {
    /// Returns true if the post is a draft and has never been uploaded to the server.
    var isLocalDraft: Bool {
        return self.isDraft() && !self.hasRemote()
    }

    var isLocalRevision: Bool {
        return self.originalIsDraft() && self.isRevision() && self.remoteStatus == .local
    }

    /// Count posts that have never been uploaded to the server.
    ///
    /// - Parameter context: A `NSManagedObjectContext` in which to count the posts
    /// - Returns: number of local posts in the given context.
    static func countLocalPosts(using context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<AbstractPost>(entityName: NSStringFromClass(AbstractPost.self))
        request.predicate = NSPredicate(format: "postID = NULL OR postID <= 0")
        return (try? context.count(for: request)) ?? 0
    }
}
