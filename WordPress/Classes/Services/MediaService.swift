import Foundation

extension MediaService {

    /// This method checks the status of all media objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of media are happening.
    ///
    /// - Parameters:
    ///   - onCompletion: block to invoke when status update is finished.
    ///   - onError: block to invoke if any error occurs while the update is being made.
    ///
    func refreshMediaStatus(onCompletion: (() -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
        self.managedObjectContext.perform {
            let fetch = NSFetchRequest<Media>(entityName: Media.classNameWithoutNamespaces())
            let pushingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.pushing.rawValue))
            let processingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.processing.rawValue))
            let errorPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.failed.rawValue))
            fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate, errorPredicate])
            do {
                let mediaPushing = try self.managedObjectContext.fetch(fetch)
                for media in mediaPushing {
                    if (media.remoteStatus == .pushing || media.remoteStatus == .processing) {
                        media.remoteStatus = .failed
                    } else if media.remoteStatus == .failed,
                        let error = media.error as NSError?, error.domain == MediaServiceErrorDomain && error.code == MediaServiceError.fileDoesNotExist.rawValue {
                        self.managedObjectContext.delete(media)
                    }
                }

                ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                    DispatchQueue.main.async {
                        onCompletion?()
                    }
                })

            } catch {
                DDLogError("Error while attempting to clean local media: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        onError?(error)
                    }
            }
        }
    }
}
