extension Post {

    /// This method checks the status of all post objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of posts are happening.
    ///
    /// - Parameters:
    ///   - onCompletion: block to invoke when status update is finished.
    ///   - onError: block to invoke if any error occurs while the update is being made.
    static func refreshStatus(with coreDataStack: CoreDataStack) {
        coreDataStack.performAndSave { context in
            let fetch = NSFetchRequest<Post>(entityName: Post.classNameWithoutNamespaces())
            let pushingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue))
            let processingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
            fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate])
            let postsPushing = (try? context.fetch(fetch)) ?? []
            for post in postsPushing {
                post.markAsFailedAndDraftIfNeeded()
            }
        }
    }
}
