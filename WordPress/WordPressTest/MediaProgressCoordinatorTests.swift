import Foundation
@testable import WordPress

class MediaProgressCoordinatorTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!
    var mediaProgressCoordinator: MediaProgressCoordinator!

    fileprivate func newTestMedia() -> Media {
        return NSEntityDescription.insertNewObject(forEntityName: Media.classNameWithoutNamespaces(), into: context) as! Media
    }

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
        mediaProgressCoordinator = MediaProgressCoordinator()
    }

    override func tearDown() {
        context.rollback()
        ContextManager.overrideSharedInstance(nil)
        mediaProgressCoordinator = nil
        super.tearDown()
    }

    func testSimpleOneUpload() {
        let mediaProgressCoordinator = MediaProgressCoordinator()

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")

        let progress = Progress.discreteProgress(totalUnitCount: 4)
        mediaProgressCoordinator.track(progress: progress, of: self.newTestMedia(), withIdentifier: "progress")
        XCTAssertTrue(mediaProgressCoordinator.isRunning, "Coordinator should be running")
        XCTAssertTrue(mediaProgressCoordinator.cancelledMediaIDs.isEmpty, "No cancelled ids")
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
        mediaProgressCoordinator.track(progress: progress, of: self.newTestMedia(), withIdentifier: "progress1")
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
        mediaProgressCoordinator.track(progress: progress1, of: self.newTestMedia(), withIdentifier: "progress1")
        mediaProgressCoordinator.track(progress: progress2, of: self.newTestMedia(), withIdentifier: "progress2")

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

    func testAddToMediaProgress() {
        let totalItems = 10

        mediaProgressCoordinator.track(numberOfItems: totalItems)
        XCTAssertNotNil(mediaProgressCoordinator.mediaGlobalProgress, "Progress should exist")

        XCTAssertTrue(mediaProgressCoordinator.mediaGlobalProgress!.totalUnitCount == Int64(totalItems), "There should a total number of 10 items")

        XCTAssertTrue(mediaProgressCoordinator.isRunning)

        for index in 1...totalItems {
            let progress = Progress.discreteProgress(totalUnitCount: 1)
            mediaProgressCoordinator.track(progress: progress, of: self.newTestMedia(), withIdentifier: "\(index)")
            progress.completedUnitCount = 1
            XCTAssertTrue(mediaProgressCoordinator.mediaGlobalProgress!.completedUnitCount == Int64(index))
        }

        XCTAssertFalse(mediaProgressCoordinator.isRunning)
    }

    func testMediaProgressThatFails() {

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertNotNil(mediaProgressCoordinator.mediaGlobalProgress, "Progress should exist")

        XCTAssertTrue(mediaProgressCoordinator.mediaGlobalProgress!.totalUnitCount == Int64(1), "There should 1 item")

        let progress = Progress.discreteProgress(totalUnitCount: 1)
        mediaProgressCoordinator.track(progress: progress, of: self.newTestMedia(), withIdentifier: "\(index)")

        XCTAssertTrue(mediaProgressCoordinator.isRunning)
        // simulate a failed request
        progress.totalUnitCount = 0
        progress.completedUnitCount = 0

        XCTAssertTrue(mediaProgressCoordinator.mediaGlobalProgress!.completedUnitCount == 0)

        XCTAssertFalse(mediaProgressCoordinator.isRunning)
    }

    func testMediaProgressThatIsCanceled() {

        mediaProgressCoordinator.track(numberOfItems: 1)
        XCTAssertNotNil(mediaProgressCoordinator.mediaGlobalProgress, "Progress should exist")

        XCTAssertTrue(mediaProgressCoordinator.mediaGlobalProgress!.totalUnitCount == Int64(1), "There should 1 item")

        let progress = Progress.discreteProgress(totalUnitCount: 1)
        mediaProgressCoordinator.track(progress: progress, of: self.newTestMedia(), withIdentifier: "\(index)")

        XCTAssertTrue(mediaProgressCoordinator.isRunning)

        // simulate a canceled request
        progress.cancel()

        XCTAssertFalse(mediaProgressCoordinator.mediaGlobalProgress!.isCancelled)

        XCTAssertFalse(mediaProgressCoordinator.isRunning)
    }
}
