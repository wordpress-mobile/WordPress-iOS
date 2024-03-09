import Foundation
@testable import WordPress

class MediaBuilder {
    private let context: NSManagedObjectContext
    private var media: Media

    init(_ context: NSManagedObjectContext) {
        self.context = context
        self.media = NSEntityDescription.insertNewObject(forEntityName: Media.entityName(), into: context) as! Media
    }

    /// Builds a media object.
    ///
    /// - Returns: the new test media object.
    ///
    @discardableResult
    func build(_ customize ((Media) -> Void) = { _ in }) -> Media {
        customize(media)
        return media
    }

    func with(autoUploadFailureCount: Int) -> Self {
        media.autoUploadFailureCount = NSNumber(value: autoUploadFailureCount)

        return self
    }

    func with(remoteStatus: MediaRemoteStatus) -> Self {
        media.remoteStatus = remoteStatus

        return self
    }
}
