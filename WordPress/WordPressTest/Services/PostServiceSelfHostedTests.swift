
import Foundation
import Nimble
@testable import WordPress

/// Tests unique behaviors of self-hosted sites.
///
/// Most the time, self-hosted, WPCom, and Jetpack sites behave the same. So, these common tests
/// are currently in `PostServiceWPComTests`.
///
/// - SeeAlso: PostServiceWPComTests
///
class PostServiceSelfHostedTests: XCTestCase {

    private var remoteMock: PostServiceXMLRPCMock!
    private var service: PostService!
    private var context: NSManagedObjectContext!

    private let impossibleFailureBlock: (Error?) -> Void = { _ in
        assertionFailure("This shouldn't happen.")
    }

    override func setUp() {
        super.setUp()

        context = TestContextManager().mainContext

        remoteMock = PostServiceXMLRPCMock()

        let remoteFactory = PostServiceRemoteFactoryMock()
        remoteFactory.remoteToReturn = remoteMock
        service = PostService(managedObjectContext: context, postServiceRemoteFactory: remoteFactory)
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        remoteMock = nil
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testAutoSavingALocalDraftWillCallTheCreateEndpointInstead() {
        // Arrange
        let post = PostBuilder(context).drafted().with(remoteStatus: .local).build()
        try! context.save()

        remoteMock.remotePostToReturnOnCreatePost = createRemotePost(.draft)

        // Act
        waitUntil(timeout: 3) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfCreatePost).to(equal(1))
        expect(post.remoteStatus).to(equal(.sync))
    }

    /// Local drafts with `.published` status will be ignored.
    func testAutoSavingALocallyPublishedDraftWillFail() {
        // Arrange
        let post = PostBuilder(context).published().with(remoteStatus: .local).build()
        try! context.save()

        // Act
        var failureBlockCalled = false
        waitUntil(timeout: 3) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: { _ in
                failureBlockCalled = true
                done()
            })
        }

        // Assert
        expect(failureBlockCalled).to(beTrue())
        expect(post.remoteStatus).to(equal(.failed))
        expect(self.remoteMock.invocationsCountOfCreatePost).to(equal(0))
        expect(self.remoteMock.invocationsCountOfUpdate).to(equal(0))
    }

    func testUploadWithForceDraftCreationWillUploadALocallyPublishedPostAsDraft() {
        // This applies to scenarios where a published post that only exists locally previously
        // failed to upload. If the user canceled the auto-upload confirmation
        // (by pressing Cancel in the Post List), we will still upload the post as a draft.

        // Arrange
        let post = PostBuilder(context).with(status: .publish).with(remoteStatus: .local).with(title: "sequi").build()
        try! context.save()

        remoteMock.remotePostToReturnOnCreatePost = createRemotePost(.draft)

        // Act
        waitUntil(timeout: 2) { done in
            self.service.uploadPost(post, forceDraftIfCreating: true, success: { _ in
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfCreatePost).to(equal(1))
        expect(post.remoteStatus).to(equal(.sync))

        let submittedRemotePost: RemotePost = remoteMock.remotePostSubmittedOnCreatePostInvocation!
        expect(submittedRemotePost.title).to(equal("sequi"))
        expect(submittedRemotePost.status).to(equal(BasePost.Status.draft.rawValue))
    }

    private func createRemotePost(_ status: BasePost.Status = .draft) -> RemotePost {
        let remotePost = RemotePost(siteID: 1,
                                    status: status.rawValue,
                                    title: "Tenetur im",
                                    content: "Velit tempore rerum")!
        remotePost.type = "qui"
        return remotePost
    }
}

private class PostServiceRemoteFactoryMock: PostServiceRemoteFactory {
    var remoteToReturn: PostServiceRemote?

    override func forBlog(_ blog: Blog) -> PostServiceRemote? {
        return remoteToReturn
    }
}

private class PostServiceXMLRPCMock: PostServiceRemoteXMLRPC {
    var remotePostToReturnOnCreatePost: RemotePost?

    private(set) var invocationsCountOfCreatePost = 0
    private(set) var invocationsCountOfUpdate = 0

    private(set) var remotePostSubmittedOnCreatePostInvocation: RemotePost?

    override func update(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            self.invocationsCountOfUpdate += 1
            success(nil)
        }
    }

    override func createPost(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            self.remotePostSubmittedOnCreatePostInvocation = post
            self.invocationsCountOfCreatePost += 1
            success(self.remotePostToReturnOnCreatePost)
        }
    }
}
