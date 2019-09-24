extension PostService {

    /// This method checks the status of all post objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of posts are happening.
    ///
    /// - Parameters:
    ///   - onCompletion: block to invoke when status update is finished.
    ///   - onError: block to invoke if any error occurs while the update is being made.
    ///
    func refreshPostStatus(onCompletion: (() -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
        self.managedObjectContext.perform {
            let fetch = NSFetchRequest<Post>(entityName: Post.classNameWithoutNamespaces())
            let pushingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue))
            let processingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
            fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate])
            do {
                let postsPushing = try self.managedObjectContext.fetch(fetch)
                for post in postsPushing {
                    self.markAsFailedAndDraftIfNeeded(post: post)
                }

                ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                    DispatchQueue.main.async {
                        onCompletion?()
                    }
                })

            } catch {
                DDLogError("Error while attempting to update posts status: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    onError?(error)
                }
            }
        }
    }
}
