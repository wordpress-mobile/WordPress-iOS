import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostCoordinatorTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestContextManager().newDerivedContext()
    }

    override func tearDown() {
        super.tearDown()
        context = nil
    }

    func testDoNotUploadAPostWithFailedMedia() {
        let postServiceMock = PostServiceMock()
        let mediaCoordinatorMock = MediaCoordinatorMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock, mediaCoordinator: mediaCoordinatorMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg", status: .failed)
            .with(remoteStatus: .local)
            .build()
        mediaCoordinatorMock.mediaState = .failed(error: NSError())

        postCoordinator.save(post)

        expect(postServiceMock.didCallMarkAsFailedAndDraftIfNeeded).toEventually(beTrue())
        expect(postServiceMock.didCallUploadPost).to(beFalse())
    }

    func testUploadAPostWithNoFailedMedia() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg")
            .build()

        postCoordinator.save(post)

        expect(postServiceMock.didCallUploadPost).to(beTrue())
    }

    func testEventuallyMarkThePostRemoteStatusAsUploading() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg")
            .build()

        postCoordinator.save(post)

        expect(post.remoteStatus).toEventually(equal(.pushing))
    }
}

private class PostServiceMock: PostService {
    private(set) var didCallUploadPost = false
    private(set) var didCallMarkAsFailedAndDraftIfNeeded = false

    override func uploadPost(_ post: AbstractPost, success: ((AbstractPost) -> Void)?, failure: @escaping (Error?) -> Void) {
        didCallUploadPost = true
    }

    override func markAsFailedAndDraftIfNeeded(post: AbstractPost) {
        didCallMarkAsFailedAndDraftIfNeeded = true
    }
}

private class MediaCoordinatorMock: MediaCoordinator {
    var mediaState: MediaState = .ended

    override func addObserver(_ onUpdate: @escaping MediaCoordinator.ObserverBlock, for media: Media? = nil) -> UUID {
        guard let media = media else {
            return UUID()
        }

        onUpdate(media, mediaState)
        return UUID()
    }
}
