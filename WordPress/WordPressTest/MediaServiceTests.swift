import Foundation
@testable import WordPress

class MediaServiceTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var mediaService: MediaService!
    private var mediaBuilder: MediaBuilder!
    private var postBuilder: PostBuilder!

    private var context: NSManagedObjectContext {
        return contextManager.mainContext
    }

    override func setUp() {
        contextManager = TestContextManager()
        mediaService = MediaService(managedObjectContext: context)
        mediaBuilder = MediaBuilder(context)
        postBuilder = PostBuilder(context)
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

    // MARK: - Tests for failedMediaForUpload(in:forAutomatedRetry:)

    /// Requesting media for manual attempt, no previous automated retry failures
    ///
    func testThatFailedMediaForUploadInPostWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(in: post, forAutomatedRetry: false)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for manual attempt, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadInPostAfterMaxFailuresWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(in: post, forAutomatedRetry: false)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, no previous failures
    ///
    func testThatFailedMediaForUploadInPostForAutomaticRetryWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(in: post, forAutomatedRetry: true)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadInPostForAutomaticRetryAfterMaxFailuresWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = mediaService.failedMediaForUpload(in: post, forAutomatedRetry: true)

        XCTAssertEqual(failedMediaForUpload.count, 0)
    }
}
