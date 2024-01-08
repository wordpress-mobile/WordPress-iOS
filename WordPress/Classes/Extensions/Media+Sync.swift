import Foundation

extension Media {

    /// Returns a list of Media objects that should be uploaded for the given input parameters.
    ///
    /// - Parameters:
    ///     - automatedRetry: whether the media to upload is the result of an automated retry.
    ///
    /// - Returns: the Media objects that should be uploaded for the given input parameters.
    ///
    static func failedMediaForUpload(automatedRetry: Bool, in context: NSManagedObjectContext) -> [Media] {
        let request = NSFetchRequest<Media>(entityName: Media.entityName())
        let failedMediaPredicate = NSPredicate(format: "\(#keyPath(Media.remoteStatusNumber)) == %d", MediaRemoteStatus.failed.rawValue)

        if automatedRetry {
            let autoUploadFailureCountPredicate = NSPredicate(format: "\(#keyPath(Media.autoUploadFailureCount)) < %d", Media.maxAutoUploadFailureCount)

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [failedMediaPredicate, autoUploadFailureCountPredicate])
        } else {
            request.predicate = failedMediaPredicate
        }

        let media = (try? context.fetch(request)) ?? []

        return media
    }

    /// This method checks the status of all media objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of media are happening.
    ///
    /// - Parameters:
    ///   - onCompletion: block to invoke when status update is finished.
    ///   - onError: block to invoke if any error occurs while the update is being made.
    ///
    static func refreshMediaStatus(using coreDataStack: CoreDataStackSwift, onCompletion: (() -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
        coreDataStack.performAndSave({ context in
            let fetch = NSFetchRequest<Media>(entityName: Media.classNameWithoutNamespaces())
            let pushingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.pushing.rawValue))
            let processingPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.processing.rawValue))
            let errorPredicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.failed.rawValue))
            fetch.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [pushingPredicate, processingPredicate, errorPredicate])
            let mediaPushing = try context.fetch(fetch)
            for media in mediaPushing {
                // If file were in the middle of being pushed or being processed they now are failed.
                if media.remoteStatus == .pushing || media.remoteStatus == .processing {
                    media.remoteStatus = .failed
                }
                // If they failed to upload themselfs because no local copy exists then we need to delete this media object
                // This scenario can happen when media objects were created based on an asset that failed to import to the WordPress App.
                // For example a that is stored on the iCloud storage and because of the network connection failed the import process.
                if media.remoteStatus == .failed,
                    let error = media.error as NSError?, error.domain == MediaServiceErrorDomain && error.code == MediaServiceError.fileDoesNotExist.rawValue {
                    context.delete(media)
                }
            }
        }, completion: { result in
            switch result {
            case .success:
                onCompletion?()
            case let .failure(error):
                DDLogError("Error while attempting to clean local media: \(error.localizedDescription)")
                onError?(error)
            }
        }, on: .main)
    }

}
