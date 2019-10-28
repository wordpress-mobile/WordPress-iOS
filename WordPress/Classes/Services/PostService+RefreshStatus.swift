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
            let request = NSBatchUpdateRequest(entityName: Post.classNameWithoutNamespaces())
            let pushingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue))
            let processingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
            let pushingOrProcessingPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate])
            let notFailedPredicate = NSPredicate(format: "remoteStatusNumber != %@ AND NOT (postID != nil AND postID > 0)", NSNumber(value: AbstractPostRemoteStatus.failed.rawValue))
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pushingOrProcessingPredicate, notFailedPredicate])
            request.propertiesToUpdate = [
                "remoteStatusNumber": NSNumber(value: AbstractPostRemoteStatus.failed.rawValue),
                "status": NSString(string: BasePost.Status.draft.rawValue),
                "dateModified": NSDate()
            ]
            do {
                try self.managedObjectContext.execute(request)
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
