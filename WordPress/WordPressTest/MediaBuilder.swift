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
    func build() -> Media {

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

    func with(type: MediaType) -> Self {
        media.mediaType = type
        return self
    }

    func with(width: Int) -> Self {
        media.width = NSNumber(integerLiteral: width)
        return self
    }

    func with(height: Int) -> Self {
        media.height = NSNumber(integerLiteral: height)
        return self
    }

    func with(remoteURL url: URL) -> Self {
        // Notice that by requiring the input to be a URL, we can confidently access its
        // String value
        media.remoteURL = url.absoluteString
        return self
    }

    func with(remoteThumbnailURL url: URL) -> Self {
        // Notice that by requiring the input to be a URL, we can confidently access its
        // String value
        media.remoteThumbnailURL = url.absoluteString
        return self
    }

    func with(blog: Blog) -> Self {
        media.blog = blog
        return self
    }
}
