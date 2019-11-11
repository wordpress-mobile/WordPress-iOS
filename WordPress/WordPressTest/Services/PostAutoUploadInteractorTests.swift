
@testable import WordPress
import Nimble

class PostAutoUploadInteractorTests: XCTestCase {
    private var context: NSManagedObjectContext!

    private var interactor: PostAutoUploadInteractor!

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
        interactor = PostAutoUploadInteractor()
    }

    override func tearDown() {
        interactor = nil
        context = nil
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testAutoUploadActionMethodReturnsTheExpectedActions() {
        // Arrange
        let postsAndExpectedActions: [Post: PostAutoUploadInteractor.AutoUploadAction] = [
            // Local drafts are automatically uploaded
            createPost(.draft): .upload,
            // Published local drafts require confirmation
            createPost(.publish, confirmedAutoUpload: true): .upload,
            // Published local drafts with no confirmation will be remote auto-saved
            createPost(.publish): .autoSave,
            // Posts with remote that do not have confirmation will be remote auto-saved
            createPost(.draft, hasRemote: true): .autoSave,
            createPost(.publish, hasRemote: true): .autoSave,
            // Posts with remote that have confirmation will be automatically uploaded
            createPost(.draft, hasRemote: true, confirmedAutoUpload: true): .upload,
            createPost(.publish, hasRemote: true, confirmedAutoUpload: true): .upload,
            createPost(.publishPrivate, hasRemote: true, confirmedAutoUpload: true): .upload,
            createPost(.scheduled, hasRemote: true, confirmedAutoUpload: true): .upload,
            // Trash and deleted are ignored
            createPost(.trash, confirmedAutoUpload: true): .nothing,
            createPost(.deleted, confirmedAutoUpload: true): .nothing,
        ]

        // Act and Assert
        postsAndExpectedActions.forEach { post, expectedAction in
            let actualAction = interactor.autoUploadAction(for: post)

            expect(actualAction).to(equal(expectedAction))
        }
    }

    func testAutoUploadActionDoesNotApplyToUploadsThatDidntFail() {
        // Arrange
        let postsAndExpectedActions: [Post: PostAutoUploadInteractor.AutoUploadAction] = [
            createPost(.draft, remoteStatus: .local): .nothing,
            createPost(.publish, remoteStatus: .local, confirmedAutoUpload: true): .nothing,
            createPost(.publish, remoteStatus: .sync): .nothing
        ]

        // Act and Assert
        postsAndExpectedActions.forEach { post, expectedAction in
            let actualAction = interactor.autoUploadAction(for: post)

            expect(actualAction).to(equal(expectedAction))
        }
    }

    /// Test which auto-uploaded post types can be canceled by the user
    func testCancelAutoUploadMethodAppliesToDraftsAndConfirmedUploads() {
        // Arrange
        let postsAndExpectedCancelableResult: [Post: Bool] = [
            // Local drafts are automatically uploaded and do not need to be canceled. We consider
            // them to be safe.
            createPost(.draft): false,
            // Published local drafts require confirmation and can be canceled
            createPost(.publish, confirmedAutoUpload: true): true,
            createPost(.publishPrivate, confirmedAutoUpload: true): true,
            createPost(.scheduled, confirmedAutoUpload: true): true,
            // Published local drafts with no confirmation will be remote auto-saved. Remote
            // auto-saved is considered safe and do not need to be canceled. It should also happen
            // in the background without any interaction from the user.
            createPost(.publish): false,
            // Confirmed draft and published posts with remote will be automatically uploaded.
            createPost(.draft, hasRemote: true, confirmedAutoUpload: true): true,
            createPost(.publish, hasRemote: true, confirmedAutoUpload: true): true,
            // Posts with remote that have no confirmation will be remote auto-saved.
            createPost(.draft, hasRemote: true): false,
            createPost(.publish, hasRemote: true): false,
            createPost(.publishPrivate, hasRemote: true): false,
            createPost(.scheduled, hasRemote: true): false,
            // Trash and deleted are unsupported
            createPost(.trash, confirmedAutoUpload: true): false,
            createPost(.deleted, confirmedAutoUpload: true): false,
        ]

        // Act and Assert
        postsAndExpectedCancelableResult.forEach { post, expectedCancelableResult in
            let actualResult = interactor.canCancelAutoUpload(of: post)

            expect(actualResult).to(equal(expectedCancelableResult))
        }
    }

    func testReturnNothingAsPostActionWhenAttemptLimitIsReached() {
        let post = createPost(.publish, confirmedAutoUpload: true, attemptsCount: 3)

        let action = interactor.autoUploadAction(for: post)

        expect(action).to(equal(.nothing))
    }

    func testReturnUploadAsPostActionWhenAttemptLimitIsNotReached() {
        let post = createPost(.publish, confirmedAutoUpload: true, attemptsCount: 2)

        let action = interactor.autoUploadAction(for: post)

        expect(action).to(equal(.upload))
    }

    func testUnconfirmedExistingPostsOfSelfHostedSitesAreNotAutoSaved() {
        // For WPCom, unconfirmed posts are auto-saved. However, self-hosted sites do not support
        // auto-save. We just do nothing in this case.
        let blog = createBlog(supportsWPComAPI: false)
        let post = createPost(.draft, hasRemote: true, confirmedAutoUpload: false, blog: blog)

        let action = interactor.autoUploadAction(for: post)

        expect(action).to(equal(.nothing))
    }

    func testUnconfirmedLocallyPublishedPostsOfSelfHostedSitesAreUploadedAsDrafts() {
        let blog = createBlog(supportsWPComAPI: false)
        let post = createPost(.publish, confirmedAutoUpload: false, blog: blog)

        let action = interactor.autoUploadAction(for: post)

        expect(action).to(equal(.uploadAsDraft))
    }

    func testPageNotAutoUploaded() {
        let page = createPage(.draft)

        let action = interactor.autoUploadAction(for: page)

        expect(action).to(equal(.nothing))
    }
}

private extension PostAutoUploadInteractorTests {
    func createPost(_ status: BasePost.Status,
                    remoteStatus: AbstractPostRemoteStatus = .failed,
                    hasRemote: Bool = false,
                    confirmedAutoUpload: Bool = false,
                    attemptsCount: Int = 1,
                    blog: Blog? = nil) -> Post {
        let post = Post(context: context)
        post.status = status
        post.remoteStatus = remoteStatus
        post.autoUploadAttemptsCount = NSNumber(value: attemptsCount)

        if hasRemote {
            post.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        if confirmedAutoUpload {
            post.shouldAttemptAutoUpload = true
        }

        if let blog = blog {
            post.blog = blog
        } else {
            post.blog = createBlog(supportsWPComAPI: true)
        }

        return post
    }

    func createPage(_ status: BasePost.Status,
                    remoteStatus: AbstractPostRemoteStatus = .failed,
                    hasRemote: Bool = false) -> Page {
        let page = NSEntityDescription.insertNewObject(forEntityName: Page.entityName(), into: context) as! Page
        page.remoteStatus = remoteStatus

        if hasRemote {
            page.postID = NSNumber(value: Int.random(in: 1...Int.max))
        }

        return page
    }

    func createBlog(supportsWPComAPI: Bool) -> Blog {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: context) as! Blog

        if supportsWPComAPI {
            blog.supportsWPComAPI()
        }

        return blog
    }
}
