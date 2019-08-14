
@testable import WordPress
import Nimble

class PostCoordinatorAutoUploadUseCaseTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    private var uploadActionUseCase: PostCoordinator.UploadActionUseCase!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        uploadActionUseCase = PostCoordinator.UploadActionUseCase()
    }

    override func tearDown() {
        uploadActionUseCase = nil
        context = nil
        contextManager = nil
        super.tearDown()
    }

    func testAutoUploadActionMethodReturnsTheExpectedActions() {
        // Arrange
        let postsAndExpectedActions: [Post: PostCoordinator.UploadAction] = [
            // Local drafts are automatically uploaded
            createPost(.draft): .upload,
            // Published local drafts require confirmation
            createPost(.publish, confirmedAutoUpload: true): .upload,
            // Published local drafts with no confirmation will be remote auto-saved
            createPost(.publish): .remoteAutoSave,
            // Draft and published posts with remote are currently unsupported. This will be
            // fixed soon.
            createPost(.draft, hasRemote: true): .nothing,
            createPost(.publish, hasRemote: true): .nothing,
            // Other statuses are currently ignored
            createPost(.publishPrivate, confirmedAutoUpload: true): .nothing,
            createPost(.scheduled, confirmedAutoUpload: true): .nothing,
            createPost(.trash, confirmedAutoUpload: true): .nothing,
            createPost(.deleted, confirmedAutoUpload: true): .nothing,
        ]

        // Act and Assert
        postsAndExpectedActions.forEach { post, expectedAction in
            let actualAction = uploadActionUseCase.autoUploadAction(for: post)

            expect(actualAction).to(equal(expectedAction))
        }
    }

    func testAutoUploadActionDoesNotApplyToUploadsThatDidntFail() {
        // Arrange
        let postsAndExpectedActions: [Post: PostCoordinator.UploadAction] = [
            createPost(.draft, remoteStatus: .local): .nothing,
            createPost(.publish, remoteStatus: .local, confirmedAutoUpload: true): .nothing,
            createPost(.publish, remoteStatus: .sync): .nothing
        ]

        // Act and Assert
        postsAndExpectedActions.forEach { post, expectedAction in
            let actualAction = uploadActionUseCase.autoUploadAction(for: post)

            expect(actualAction).to(equal(expectedAction))
        }
    }
}

private extension PostCoordinatorAutoUploadUseCaseTests {
    func createPost(_ status: BasePost.Status,
                    remoteStatus: AbstractPostRemoteStatus = .failed,
                    hasRemote: Bool = false,
                    confirmedAutoUpload: Bool = false) -> Post {
        let post = Post(context: context)
        post.status = status
        post.remoteStatus = remoteStatus
        post.confirmedAutoUpload = confirmedAutoUpload

        if hasRemote {
            post.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        return post
    }
}
