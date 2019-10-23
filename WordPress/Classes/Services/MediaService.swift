import Foundation

extension MediaService {

    // MARK: - Failed Media for Uploading

    /// Returns a list of Media objects that should be uploaded for the given input parameters.
    ///
    /// - Parameters:
    ///     - automatedRetry: whether the media to upload is the result of an automated retry.
    ///
    /// - Returns: the Media objects that should be uploaded for the given input parameters.
    ///
    func failedMediaForUpload(automatedRetry: Bool) -> [Media] {
        let request = NSFetchRequest<Media>(entityName: Media.entityName())
        let failedMediaPredicate = NSPredicate(format: "\(#keyPath(Media.remoteStatusNumber)) == %d", MediaRemoteStatus.failed.rawValue)

        if automatedRetry {
            let autoUploadFailureCountPredicate = NSPredicate(format: "\(#keyPath(Media.autoUploadFailureCount)) < %d", Media.maxAutoUploadFailureCount)

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [failedMediaPredicate, autoUploadFailureCountPredicate])
        } else {
            request.predicate = failedMediaPredicate
        }

        let media = (try? managedObjectContext.fetch(request)) ?? []

        return media
    }

    /// Returns a list of Media objects from a post, that should be autoUploaded on the next attempt.
    ///
    /// - Parameters:
    ///     - post: the post to look auto-uploadable media for.
    ///     - automatedRetry: whether the media to upload is the result of an automated retry.
    ///
    /// - Returns: the Media objects that should be autoUploaded.
    ///
    func failedMediaForUpload(in post: AbstractPost, automatedRetry: Bool) -> [Media] {
        return post.media.filter({ media in
            return media.remoteStatus == .failed
                && (!automatedRetry || media.autoUploadFailureCount.intValue < Media.maxAutoUploadFailureCount)
        })
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
            let errorPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.failed.rawValue))
            fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate, errorPredicate])
            do {
                let mediaPushing = try self.managedObjectContext.fetch(fetch)
                for media in mediaPushing {
                    // If file were in the middle of being pushed or being processed they now are failed.
                    if media.remoteStatus == .pushing || media.remoteStatus == .processing {
                        media.remoteStatus = .failed
                    }
                    // If they failed to upload themselfs because no local copy exists then we need to delete this media object
                    // This scenario can happen when media objects were created based on an asset that failed to import to the WordPress App.
                    // For example a PHAsset that is stored on the iCloud storage and because of the network connection failed the import process.
                    if media.remoteStatus == .failed,
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

// MARK: - Factory

extension MediaService {
    class Factory {
        func create(_ context: NSManagedObjectContext) -> MediaService {
            return MediaService(managedObjectContext: context)
        }
    }
}
