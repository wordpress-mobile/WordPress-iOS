import Foundation

extension MediaService {

    // MARK: - Failed Media for Autouploading

    private static let maxUploadFailureCount = 4

    /// Returns a list of Media objects that should be autouploaded on the next attempt.
    ///
    /// - Returns: the Media objects that should be autouploaded.
    ///
    func failedMediaForAutoupload() -> [Media] {
        let request = NSFetchRequest<Media>(entityName: Media.entityName())
        request.predicate = NSPredicate(format: "\(#keyPath(Media.remoteStatusNumber)) == %d AND \(#keyPath(Media.uploadFailureCount)) < %d", MediaRemoteStatus.failed.rawValue, MediaService.maxUploadFailureCount)

        let media = (try? managedObjectContext.fetch(request)) ?? []

        return media
    }

    /// Returns a list of Media objects from a post, that should be autouploaded on the next attempt.
    ///
    /// - Parameters:
    ///     - post: the post to look auto-uploadable media for.
    ///
    /// - Returns: the Media objects that should be autouploaded.
    ///
    func failedMediaForAutoUpload(in post: AbstractPost) -> [Media] {
        return post.media.filter({ $0.remoteStatus == .failed && $0.uploadFailureCount.intValue < MediaService.maxUploadFailureCount })
    }

    // MARK: - Misc

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
            fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate])
            do {
                let mediaPushing = try self.managedObjectContext.fetch(fetch)
                for media in mediaPushing {
                    media.remoteStatus = .failed
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
