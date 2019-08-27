import Foundation

extension MediaService {

    /// Auto-uploads the specified Media object.  This method should be called whenever an upload isn't user-initiated, as it will
    /// ensure that the upload failure counter isn't reset.
    ///
    /// - Parameters:
    ///     - media: The media that will be auto-uploaded.
    ///     - inout progress: The upload progress.
    ///     - success: The success closure.
    ///     - failure: The failure closure.
    ///
    func autoupload(_ media: Media, progress: inout Progress?, success: @escaping () -> (), failure: @escaping (Error?) -> ()) {
        let managedObjectContext = self.managedObjectContext
        let mediaObjectID = media.objectID

        let failureBlock: (Error?) -> () = { error in
            guard let object = try? managedObjectContext.existingObject(with: mediaObjectID),
                let media = object as? Media else {
                    failure(error)
                    return
            }

            managedObjectContext.perform({
                media.uploadFailureCount = NSNumber(value: media.uploadFailureCount.intValue + 1)

                ContextManager.sharedInstance().save(managedObjectContext)
            })

            failure(error)
        }

        uploadMedia(media, progress: &progress, success: success, failure: failureBlock)
    }

    /// Returns a list of Media objects that should be autouploaded on the next attempt.
    ///
    /// - Returns: the Media objects that should be autouploaded.
    ///
    func failedMediaForAutoupload() -> [Media] {
        let request = NSFetchRequest<Media>(entityName: Media.entityName())

        request.predicate = NSPredicate(format: "remoteStatusNumber == %d", MediaRemoteStatus.failed.rawValue)

        return (try? request.execute()) ?? []
    }

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
