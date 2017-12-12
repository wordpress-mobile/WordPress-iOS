import Foundation

extension MediaService {

    func refreshMediaStatus(onCompletion: (() -> Void)?, onError: ((Error) -> Void)?) {
        self.managedObjectContext.perform {
            let fetch = NSFetchRequest<Media>(entityName: Media.classNameWithoutNamespaces())
            fetch.predicate = NSPredicate(format: "remoteStatusNumber = %@", NSNumber(value: MediaRemoteStatus.pushing.rawValue))
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
                if let onError = onError {
                    DispatchQueue.main.async {
                        onError(error)
                    }
                }
            }
        }
    }
}
