import Foundation

extension Media {

    // MARK: - Autoupload Failure Count

    /// Increments the autoupload failure count for this Media object.
    ///
    @objc
    func incrementAutouploadFailureCount() {
        autouploadFailureCount = NSNumber(value: autouploadFailureCount.intValue + 1)
    }

    /// Resets the autoupload failure count for this Media object.
    ///
    @objc
    func resetAutouploadFailureCount() {
        autouploadFailureCount = 0
    }
}
