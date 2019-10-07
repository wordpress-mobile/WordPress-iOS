import Nimble

@testable import WordPress

class PublishPostInteractorTests: XCTestCase {
    private var context: NSManagedObjectContext!
    private var postCoordinatorMock: PostCoordinatorMock!
    private var publishPostInteractor: PublishPostInteractor!

    override func setUp() {
        super.setUp()
        context = TestContextManager().newDerivedContext()
        postCoordinatorMock = PostCoordinatorMock()
        publishPostInteractor = PublishPostInteractor(postCoordinator: postCoordinatorMock)
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        postCoordinatorMock = nil
        publishPostInteractor = nil
    }

    func testChangeDraftToPublishWhenUploading() {
        let post = PostBuilder(context).drafted().build()

        publishPostInteractor.upload(post)

        expect(post.status).to(equal(.publish))
    }

    func testDoNotChangeDateCreatedForAScheduledPost() {
        let post = PostBuilder(context).with(dateCreated: Date(timeIntervalSince1970: 50)).scheduled().build()

        publishPostInteractor.upload(post)

        expect(post.date_created_gmt).to(equal(Date(timeIntervalSince1970: 50)))
    }

    func testSetShouldAttemptAutoUploadToTrue() {
        let post = PostBuilder(context).drafted().build()

        publishPostInteractor.upload(post)

        expect(post.shouldAttemptAutoUpload).to(beTrue())
    }

    func testCallPostCoordinatorToSaveAPost() {
        let post = PostBuilder(context).drafted().build()

        publishPostInteractor.upload(post)

        expect(self.postCoordinatorMock.didCallSave).to(beTrue())
    }
}

private class PostCoordinatorMock: PostCoordinator {
    var didCallSave = false

    override func save(_ postToSave: AbstractPost, automatedRetry: Bool = false) {
        didCallSave = true
    }
}
