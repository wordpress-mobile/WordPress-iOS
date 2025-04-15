import XCTest
import Foundation
import Nimble
@testable import WordPress

class MediaCoordinatorTests: CoreDataTestCase {
    private var coordinator: MediaCoordinator!

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        coordinator = MediaCoordinator(MediaServiceFactoryMock(), coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
    }

    func testUploadMediaReturnsTrueIfAllPendingMediaAreQueuedForUpload() {
        let post = PostBuilder(mainContext)
            .with(image: "test.jpg", status: .failed)
            .with(image: "test-002.jpg", status: .failed)
            .with(image: "test-003.jpg", status: .local)
            .build()
        try! mainContext.save()

        let isPushingAllPendingMedia = coordinator.uploadMedia(for: post, automatedRetry: true)

        expect(isPushingAllPendingMedia).to(beTrue())
    }

    func testUploadMediaReturnsFalseIfNotAllPendingMediaAreQueuedForUpload() {
        let post = PostBuilder(mainContext)
            .with(image: "test.jpg", status: .failed)
            // This media has exceeded the maximum failure count and will not be queued
            .with(image: "test-002.jpg", status: .failed, autoUploadFailureCount: 10)
            .build()
        try! mainContext.save()

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
