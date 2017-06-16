import Foundation
@testable import WordPress

class MediaProgressCoordinatorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSimpleOneUpload() {
        let mediaProgressCoordinator = MediaProgressCoordinator()

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")

        let progress = Progress.discreteProgress(totalUnitCount: 4)
        mediaProgressCoordinator.track(progress: progress, ofObject: "progress", withMediaID: "progress")
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")
        XCTAssertTrue(mediaProgressCoordinator.allCancelledIDs.isEmpty, "No cancelled ids")
        XCTAssertTrue(mediaProgressCoordinator.failedMediaIDs.isEmpty, "No failed ids")
        XCTAssertEqual(0, mediaProgressCoordinator.totalProgress, "Total progress should be 0")

        progress.completedUnitCount += 1
        XCTAssertEqual(0.25, mediaProgressCoordinator.totalProgress, "Total progress should be 0.25")

        progress.completedUnitCount += 1
        XCTAssertEqual(0.5, mediaProgressCoordinator.totalProgress, "Total progress should be 0.5")

        progress.completedUnitCount += 1
        XCTAssertEqual(0.75, mediaProgressCoordinator.totalProgress, "Total progress should be 0.75")

        progress.completedUnitCount += 1
        XCTAssertEqual(1, mediaProgressCoordinator.totalProgress, "Total progress should be 1")

        XCTAssertFalse(mediaProgressCoordinator.isRunning, "Coordinator should be stopped")
        XCTAssertFalse(mediaProgressCoordinator.hasFailedMedia, "Coordinator should not have failed media")
    }

    func testSimpleOneUploadThatIsCancelled() {
        let mediaProgressCoordinator = MediaProgressCoordinator()

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")

        let progress = Progress.discreteProgress(totalUnitCount: 4)
        mediaProgressCoordinator.track(progress: progress, ofObject: "progress1", withMediaID: "progress1")
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")
        XCTAssertEqual(0, mediaProgressCoordinator.totalProgress, "Total progress should be 0")

        progress.completedUnitCount += 1
        XCTAssertEqual(0.25, mediaProgressCoordinator.totalProgress, "Total progress should be 0.25")

        progress.completedUnitCount += 1
        XCTAssertEqual(0.5, mediaProgressCoordinator.totalProgress, "Total progress should be 0.5")

        progress.completedUnitCount += 1
        XCTAssertEqual(0.75, mediaProgressCoordinator.totalProgress, "Total progress should be 0.75")

        progress.cancel()
        XCTAssertEqual(0.75, mediaProgressCoordinator.totalProgress, "Total progress should be 0.75")

        XCTAssertFalse(mediaProgressCoordinator.isRunning, "Coordinator should be stopped")
        XCTAssertFalse(mediaProgressCoordinator.hasFailedMedia, "Coordinator should have failed media")
    }

    func testTwoUploads() {
        let mediaProgressCoordinator = MediaProgressCoordinator()

        mediaProgressCoordinator.track(numberOfItems: 2)
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")

        let progress1 = Progress.discreteProgress(totalUnitCount: 2)
        let progress2 = Progress.discreteProgress(totalUnitCount: 2)
        mediaProgressCoordinator.track(progress: progress1, ofObject: "progress1", withMediaID: "progress1")
        mediaProgressCoordinator.track(progress: progress2, ofObject: "progress2", withMediaID: "progress2")

        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")
        XCTAssertEqual(0, mediaProgressCoordinator.totalProgress, "Total progress should be 0")

        progress1.completedUnitCount += 1
        XCTAssertEqual(0.25, mediaProgressCoordinator.totalProgress, "Total progress should be 0.25")

        progress1.completedUnitCount += 1
        XCTAssertEqual(0.5, mediaProgressCoordinator.totalProgress, "Total progress should be 0.5")

        progress2.completedUnitCount += 1
        XCTAssertEqual(0.75, mediaProgressCoordinator.totalProgress, "Total progress should be 0.75")

        progress2.completedUnitCount += 1
        XCTAssertEqual(1, mediaProgressCoordinator.totalProgress, "Total progress should be 1")

        XCTAssertFalse(mediaProgressCoordinator.isRunning, "Coordinator should be stopped")
        XCTAssertFalse(mediaProgressCoordinator.hasFailedMedia, "Coordinator should not have failed media")
    }
}
