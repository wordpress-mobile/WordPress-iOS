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
            let failedRequest = NSBatchUpdateRequest(entityName: AbstractPost.classNameWithoutNamespaces())
            let draftRequest = NSBatchUpdateRequest(entityName: AbstractPost.classNameWithoutNamespaces())
            let pushingOrProcessingPredicate = NSPredicate(format: "remoteStatusNumber = %@ OR remoteStatusNumber = %@", NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue), NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
            let notFailedPredicate = NSPredicate(format: "remoteStatusNumber != %@", NSNumber(value: AbstractPostRemoteStatus.failed.rawValue))
            let pushingOrProcessingAndNotFailedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pushingOrProcessingPredicate, notFailedPredicate])
            let draftPredicate = NSPredicate(format: "entity = %@ AND NOT (postID != nil AND postID > 0)", Page.entity())
            failedRequest.predicate = pushingOrProcessingAndNotFailedPredicate
            draftRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pushingOrProcessingAndNotFailedPredicate, draftPredicate])
            failedRequest.propertiesToUpdate = ["remoteStatusNumber": NSNumber(value: AbstractPostRemoteStatus.failed.rawValue)]
            draftRequest.propertiesToUpdate = [
                "status": NSString(string: BasePost.Status.draft.rawValue),
                "dateModified": NSDate()
            ]
            do {
                try self.managedObjectContext.execute(failedRequest)
                try self.managedObjectContext.execute(draftRequest)
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
