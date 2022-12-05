import Foundation
@testable import WordPress
import XCTest

class MediaServiceTests: CoreDataTestCase {
    private var mediaService: MediaService!
    private var mediaBuilder: MediaBuilder!
    private var postBuilder: PostBuilder!

    override func setUp() {
        mediaService = MediaService(managedObjectContext: mainContext)
        mediaBuilder = MediaBuilder(mainContext)
        postBuilder = PostBuilder(mainContext)
    }

    // MARK: - Tests for failedMediaForUpload(automatedRetry:)

    /// Requesting media for manual attempt, no previous automated retry failures
    ///
    func testThatFailedMediaForUploadWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()

        let failedMediaForUpload = Media.failedMediaForUpload(automatedRetry: false, in: mainContext)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for manual attempt, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadAfterMaxFailuresWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()

        let failedMediaForUpload = Media.failedMediaForUpload(automatedRetry: false, in: mainContext)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, no previous failures
    ///
    func testThatFailedMediaForUploadForAutomaticRetryWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()

        let failedMediaForUpload = Media.failedMediaForUpload(automatedRetry: true, in: mainContext)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadForAutomaticRetryAfterMaxFailuresWorks() {
        mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()

        let failedMediaForUpload = Media.failedMediaForUpload(automatedRetry: true, in: mainContext)

        XCTAssertEqual(failedMediaForUpload.count, 0)
    }

    // MARK: - Tests for failedMediaForUpload(in:automatedRetry:)

    /// Requesting media for manual attempt, no previous automated retry failures
    ///
    func testThatFailedMediaForUploadInPostWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = Media.failedForUpload(in: post, automatedRetry: false)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for manual attempt, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadInPostAfterMaxFailuresWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = Media.failedForUpload(in: post, automatedRetry: false)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, no previous failures
    ///
    func testThatFailedMediaForUploadInPostForAutomaticRetryWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = Media.failedForUpload(in: post, automatedRetry: true)

        XCTAssertTrue(failedMediaForUpload.contains(media))
        XCTAssertEqual(failedMediaForUpload.count, 1)
    }

    /// Requesting media for automated retry, after `Media.maxAutoUploadFailureCount` automated retries failed
    ///
    func testThatFailedMediaForUploadInPostForAutomaticRetryAfterMaxFailuresWorks() {
        let media = mediaBuilder.with(remoteStatus: .failed).with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()
        let post = postBuilder.with(media: [media]).build()

        let failedMediaForUpload = Media.failedForUpload(in: post, automatedRetry: true)

        XCTAssertEqual(failedMediaForUpload.count, 0)
    }

    // MARK: - Deleting Media

    func testDeletingLocalMediaThatDoesntExistInCoreData() {
        let firstDeleteSucceeds = expectation(description: "The delete call succeeds even if the media object isn't saved.")
        let secondDeleteSucceeds = expectation(description: "The delete call succeeds even if the media object isn't saved.")

        let media = mediaBuilder
            .with(remoteStatus: .failed)
            .with(autoUploadFailureCount: Media.maxAutoUploadFailureCount).build()

        mediaService.delete(media) {
            firstDeleteSucceeds.fulfill()
        } failure: { error in
            XCTFail("Media deletion failed with error: \(error)")
        }

        mediaService.delete(media) {
            secondDeleteSucceeds.fulfill()
        } failure: { error in
            XCTFail("Media deletion failed with error: \(error)")
        }

        waitForExpectations(timeout: 0.1)
    }
}
