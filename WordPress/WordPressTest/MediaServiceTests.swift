import Foundation
@testable import WordPress

class MediaServiceTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var mediaService: MediaService!
    private var mediaBuilder: MediaBuilder!

    private var context: NSManagedObjectContext {
        return contextManager.mainContext
    }

    override func setUp() {
        contextManager = TestContextManager()
        mediaBuilder = MediaBuilder(withContext: context)
        mediaService = MediaService(managedObjectContext: context)
    }

    // MARK: - Tests for failedMediaForUpload(forAutomatedRetry:)

    /// Requesting media for manual attempt, no previous automated retry failures
    ///
    func testThatFailedMediaForUploadWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(forAutomatedRetry: false)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for manual attempt, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadAfterMaxFailuresWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(forAutomatedRetry: false)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, no previous failures
    ///
    func testThatFailedMediaForUploadForAutomaticRetryWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(forAutomatedRetry: true)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadForAutomaticRetryAfterMaxFailuresWorks() {
        mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(forAutomatedRetry: true)

        XCTAssertEqual(failedMediaForUpload.count, 0)
    }
}
