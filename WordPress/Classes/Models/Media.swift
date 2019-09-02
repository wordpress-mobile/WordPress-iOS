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
}
