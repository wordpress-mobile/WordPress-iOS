
import Foundation
import Nimble
@testable import WordPress

class MediaCoordinatorTests: XCTestCase {
    private var context: NSManagedObjectContext!

    private var coordinator: MediaCoordinator!

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
        coordinator = MediaCoordinator(MediaServiceFactoryMock())
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testUploadMediaReturnsTrueIfAllPendingMediaAreQueuedForUpload() {
        let post = PostBuilder(context)
            .with(image: "test.jpg", status: .failed)
            .with(image: "test-002.jpg", status: .failed)
            .with(image: "test-003.jpg", status: .local)
            .build()
        try! context.save()

        let isPushingAllPendingMedia = coordinator.uploadMedia(for: post, automatedRetry: true)

        expect(isPushingAllPendingMedia).to(beTrue())
    }

    func testUploadMediaReturnsFalseIfNotAllPendingMediaAreQueuedForUpload() {
        let post = PostBuilder(context)
            .with(image: "test.jpg", status: .failed)
            // This media has exceeded the maximum failure count and will not be queued
            .with(image: "test-002.jpg", status: .failed, autoUploadFailureCount: 10)
            .build()
        try! context.save()

        let isPushingAllPendingMedia = coordinator.uploadMedia(for: post, automatedRetry: true)

        expect(isPushingAllPendingMedia).to(beFalse())
    }
}

private class MediaServiceFactoryMock: MediaService.Factory {
    override func create(_ context: NSManagedObjectContext) -> MediaService {
        return MediaServiceMock(managedObjectContext: context)
    }
}

private class MediaServiceMock: MediaService {
    override func uploadMedia(_ media: Media, automatedRetry: Bool,
                              progress: AutoreleasingUnsafeMutablePointer<Progress?>?,
                              success: (() -> Void)?,
                              failure: ((Error?) -> Void)? = nil) {
        DispatchQueue.global().async {
            success?()
        }
    }
}
