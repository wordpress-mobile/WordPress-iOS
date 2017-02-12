import XCTest
@testable import WordPress

class MediaProgressCoordinatorTest: XCTestCase {

    var mediaProgressCoordinator: MediaProgressCoordinator!

    override func setUp() {
        super.setUp()
        mediaProgressCoordinator = MediaProgressCoordinator()
    }

    override func tearDown() {
        super.tearDown()
        mediaProgressCoordinator = nil
    }

    func testAddToMediaProgress() {
        let totalItems = 10

        mediaProgressCoordinator.track(numberOfItems: totalItems)
        XCTAssertNotNil(mediaProgressCoordinator.mediaUploadingProgress, "Progress should exist")

        XCTAssertTrue(mediaProgressCoordinator.mediaUploadingProgress!.totalUnitCount == Int64(totalItems), "There should a total number of 10 items")

        XCTAssertTrue(mediaProgressCoordinator.isRunning)

        for index in 1...totalItems {
            let progress = Progress.discreteProgress(totalUnitCount: 1)
            mediaProgressCoordinator.track(progress: progress, ofObject:index , withMediaID: "/(index)")
            progress.completedUnitCount = 1
            XCTAssertTrue(mediaProgressCoordinator.mediaUploadingProgress!.completedUnitCount == Int64(index))
        }

        XCTAssertFalse(mediaProgressCoordinator.isRunning)
    }

    func testMediaProgressThatFails() {

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertNotNil(mediaProgressCoordinator.mediaUploadingProgress, "Progress should exist")

        XCTAssertTrue(mediaProgressCoordinator.mediaUploadingProgress!.totalUnitCount == Int64(1), "There should 1 item")

        let progress = Progress.discreteProgress(totalUnitCount: 1)
        mediaProgressCoordinator.track(progress: progress, ofObject:1 , withMediaID: "/(index)")

        XCTAssertTrue(mediaProgressCoordinator.isRunning)
        // simulate a failed request
        progress.totalUnitCount = 0
        progress.completedUnitCount = 0

        XCTAssertTrue(mediaProgressCoordinator.mediaUploadingProgress!.completedUnitCount == 0)

        XCTAssertFalse(mediaProgressCoordinator.isRunning)
    }

    func testMediaProgressThatIsCanceled() {

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertNotNil(mediaProgressCoordinator.mediaUploadingProgress, "Progress should exist")

        XCTAssertTrue(mediaProgressCoordinator.mediaUploadingProgress!.totalUnitCount == Int64(1), "There should 1 item")

        let progress = Progress.discreteProgress(totalUnitCount: 1)
        mediaProgressCoordinator.track(progress: progress, ofObject:1 , withMediaID: "/(index)")

        XCTAssertTrue(mediaProgressCoordinator.isRunning)

        // simulate a canceled request
        progress.cancel()

        XCTAssertFalse(mediaProgressCoordinator.mediaUploadingProgress!.isCancelled)

        XCTAssertFalse(mediaProgressCoordinator.isRunning)
    }

}
