import Foundation

extension Media {

    // MARK: - AutoUpload Failure Count

    static let maxAutoUploadFailureCount = 3

    /// Increments the AutoUpload failure count for this Media object.
    ///
    @objc
    func incrementAutoUploadFailureCount() {
        autoUploadFailureCount = NSNumber(value: autoUploadFailureCount.intValue + 1)
    }

    /// Resets the AutoUpload failure count for this Media object.
    ///
    @objc
    func resetAutoUploadFailureCount() {
        autoUploadFailureCount = 0
    }
    /// Returns true if a new attempt to upload the media will be done later.
    /// Otherwise, false.
    ///
    func willAttemptToUploadLater() -> Bool {
        return autoUploadFailureCount.intValue < Media.maxAutoUploadFailureCount
    }

    /// Returns true if media has any associated post
    ///
    func hasAssociatedPost() -> Bool {
        guard let posts = posts else {
            return false
        }

        return !posts.isEmpty
    }

    // MARK: - Media Link

    var link: String {
        get {
            guard let siteURL = self.blog.url,
                let mediaID = self.mediaID else {
                return ""
            }
            return "\(siteURL)/?p=\(mediaID)"
        }
    }
}
