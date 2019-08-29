import Foundation

extension PostService {

    // MARK: - Failed Media for Uploading

    /// Returns `true` if the post has failed media that cannot be Auto Uploaded because autoUploads failed
    /// too many times.
    ///
    func hasFailedMediaThatCannotBeAutoUploaded(_ post: AbstractPost) -> Bool {
        return post.media.first(where: { media -> Bool in
            return media.remoteStatus == .failed && media.autoUploadFailureCount.intValue >= Media.maxAutoUploadFailureCount
        }) != nil
    }

    /// Returns a list of Media objects from a post, that should be autoUploaded on the next attempt.
    ///
    /// - Parameters:
    ///     - post: the post to look auto-uploadable media for.
    ///
    /// - Returns: the Media objects that should be autoUploaded.
    ///
    func failedMediaForUpload(in post: AbstractPost, forAutomatedRetry: Bool) -> [Media] {
        return post.media.filter({ media in
            return media.remoteStatus == .failed
                && (!forAutomatedRetry || media.autoUploadFailureCount.intValue < Media.maxAutoUploadFailureCount)
        })
    }
}
