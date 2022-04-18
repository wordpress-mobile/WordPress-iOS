
import Foundation
import Nimble
@testable import WordPress

/// Tests common and WPCom-only PostService behavior.
///
/// - SeeAlso: PostServiceSelfHostedTests
///
class PostServiceWPComTests: XCTestCase {

    private var remoteMock: PostServiceRESTMock!
    private var service: PostService!
    private var context: NSManagedObjectContext!

    private let impossibleFailureBlock: (Error?) -> Void = { _ in
        assertionFailure("This shouldn't happen.")
    }

    override func setUp() {
        super.setUp()

        context = TestContextManager().mainContext

        remoteMock = PostServiceRESTMock()

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

    func testGettingANewPostFromTheAPIWillSetTheStatusAfterSyncProperty() {
        // Arrange
        let blog = BlogBuilder(context).build()
        remoteMock.remotePostToReturnOnGetPostWithID = createRemotePost(.scheduled)

        // Act
        var post: AbstractPost?
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.getPostWithID(123, for: blog, success: { postFromAPI in
                post = postFromAPI
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(post).notTo(beNil())
        expect(post?.status).to(equal(.scheduled))
        expect(post?.statusAfterSync).to(equal(.scheduled))
        expect(post?.status).to(equal(post?.statusAfterSync))
    }

    func testSyncingPostsWillSetTheStatusAfterSyncProperty() {
        // Arrange
        let blog = BlogBuilder(context).build()
        remoteMock.remotePostsToReturnOnSyncPostsOfType =
            [createRemotePost(.scheduled), createRemotePost(.publishPrivate)]

        // Act
        var posts: [AbstractPost]?
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.syncPosts(ofType: .any, for: blog, success: { postsFromAPI in
                posts = postsFromAPI
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        let expectedStatuses: [BasePost.Status] = [.publishPrivate, .scheduled]

        expect(posts).to(haveCount(2))
        posts?.forEach { post in
            expect(expectedStatuses as NMBContainer).to(contain(post.status))
            expect(expectedStatuses as NMBContainer).to(contain(post.statusAfterSync))
            expect(post.status).to(equal(post.statusAfterSync))
        }
    }

    func testUpdatingAPostWillUpdateItsStatusAfterSyncProperty() {
        // Arrange
        let post = PostBuilder(context).with(statusAfterSync: .publish).drafted().withRemote().build()
        try! context.save()

        let remotePost = createRemotePost(.draft)
        remoteMock.remotePostToReturnOnUpdatePost = remotePost

        // Act
        var postFromAPI: AbstractPost?
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.uploadPost(post, success: { aPost in
                postFromAPI = aPost
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(postFromAPI).notTo(beNil())

        // Refetch from DB to make sure we're getting the updated data.
        let postFromDB = context.object(with: postFromAPI!.objectID) as! AbstractPost
        // .draft is the status because it's what the returned RemotePost has
        expect(postFromDB.statusAfterSync).to(equal(.draft))
        expect(postFromDB.status).to(equal(.draft))
    }

    func testTrashingAPostWillUpdateItsRevisionStatusAfterSyncProperty() {
        // Arrange
        let post = PostBuilder(context).with(statusAfterSync: .publish).withRemote().build()
        let revision = post.createRevision()
        try! context.save()

        let remotePost = createRemotePost(.trash)
        remoteMock.remotePostToReturnOnTrashPost = remotePost

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
         self.service.trashPost(post, success: {
             done()
         }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(post.statusAfterSync).to(equal(.trash))
        expect(post.status).to(equal(.trash))
        expect(revision.statusAfterSync).to(equal(.trash))
        expect(revision.status).to(equal(.trash))
     }

    func testAutoSavingALocalDraftWillCallTheCreateEndpointInstead() {
        // Arrange
        let post = PostBuilder(context).drafted().with(remoteStatus: .local).build()
        try! context.save()

        remoteMock.remotePostToReturnOnCreatePost = createRemotePost(.draft)

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfCreatePost).to(equal(1))
        expect(post.remoteStatus).to(equal(.sync))
    }

    func testAutoSavingADraftWillCallTheUpdateEndpointInstead() {
        // Arrange
        let post = PostBuilder(context).with(statusAfterSync: .draft).drafted().withRemote().build()
        try! context.save()

        let remotePost = createRemotePost(.draft)
        remoteMock.remotePostToReturnOnUpdatePost = remotePost
        remoteMock.remotePostToReturnOnGetPostWithID = remotePost

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfUpdate).to(equal(1))
        expect(post.remoteStatus).to(equal(.sync))
    }

    /// Local drafts with `.published` status will be created on the server as a `.draft`.
    func testAutoSavingALocallyPublishedDraftWillCreateThePostAsADraft() {
        // Arrange
        let post = PostBuilder(context).published().with(remoteStatus: .local).build()
        try! context.save()

        remoteMock.remotePostToReturnOnCreatePost = createRemotePost(.draft)

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfCreatePost).to(equal(1))
        expect(post.remoteStatus).to(equal(.sync))
    }

    /// Local drafts with `.trash` status will not be automatically created on the server.
    func testAutoSavingALocallyTrashedPostWillFail() {
        // Arrange
        let post = PostBuilder(context).trashed().with(remoteStatus: .local).build()
        try! context.save()

        // Act
        var failureBlockCalled = false
        waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: { _ in
                failureBlockCalled = true
                done()
            })
        }

        // Assert
        expect(failureBlockCalled).to(beTrue())
    }

    func testAutoSavingAnExistingPostWillCallTheAutoSaveEndpoint() {
        // Arrange
        let post = PostBuilder(context).published().withRemote().with(remoteStatus: .sync).build()
        try! context.save()

        remoteMock.autoSaveStubbedBehavior = .success(createRemotePost(.publish))

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(3)) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: self.impossibleFailureBlock)
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfAutoSave).to(equal(1))
        expect(post.remoteStatus).to(equal(.autoSaved))
    }

    func testAnAutoSaveFailureWillSetTheRemoteStatusToFailed() {
        // Arrange
        let post = PostBuilder(context).published().withRemote().with(remoteStatus: .sync).build()
        try! context.save()

        remoteMock.autoSaveStubbedBehavior = .fail

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
            self.service.autoSave(post, success: { _, _ in
                done()
            }, failure: { _ in
                done()
            })
        }

        // Assert
        expect(self.remoteMock.invocationsCountOfAutoSave).to(equal(1))
        expect(post.remoteStatus).to(equal(.failed))
    }

    func testFetchingPostLikesSuccessfullyShouldCallSuccessBlock() {
        // Arrange
        let postID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        let expectedUsers = [createRemoteLikeUser()]
        try! context.save()
        remoteMock.remoteUsersToReturnOnGetLikes = expectedUsers

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
            self.service.getLikesFor(postID: postID, siteID: siteID, success: { users, totalLikes, likesPerPage in
                // Assert
                expect(users.count) == 1
                expect(likesPerPage) > 0
                done()
            },
            failure: { _ in
                fail("This closure should not be called")
            })
        }
    }

    func testFailingFetchPostLikesShouldCallFailureBlock() {
        // Arrange
        let postID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        try! context.save()
        remoteMock.fetchLikesShouldSucceed = false

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
            self.service.getLikesFor(postID: postID, siteID: siteID, success: { users, totalLikes, likesPerPage in
                fail("this closure should not be called")
            },
            failure: { _ in
                done()
            })
        }
    }

    private func createRemotePost(_ status: BasePost.Status = .draft) -> RemotePost {
        let remotePost = RemotePost(siteID: 1,
                                    status: status.rawValue,
                                    title: "Tenetur im",
                                    content: "Velit tempore rerum")!
        remotePost.type = "qui"
        return remotePost
    }

    private func createRemoteLikeUser() -> RemoteLikeUser {
        let userDict: [String: Any] = [ "ID": NSNumber(value: 123),
                                        "login": "johndoe",
                                        "name": "John Doe",
                                        "site_ID": NSNumber(value: 456),
                                        "avatar_URL": "avatar URL",
                                        "date_liked": "2021-02-09 08:34:43"
        ]

        return RemoteLikeUser(dictionary: userDict, postID: NSNumber(value: 1), siteID: NSNumber(value: 2))
    }
}

private class PostServiceRemoteFactoryMock: PostServiceRemoteFactory {
    var remoteToReturn: PostServiceRemote?

    override func forBlog(_ blog: Blog) -> PostServiceRemote? {
        return remoteToReturn
    }

    override func restRemoteFor(siteID: NSNumber, context: NSManagedObjectContext) -> PostServiceRemoteREST? {
        return remoteToReturn as? PostServiceRemoteREST
    }
}

private class PostServiceRESTMock: PostServiceRemoteREST {
    enum StubbedBehavior {
        case success(RemotePost?)
        case fail
    }

    var remotePostToReturnOnGetPostWithID: RemotePost?
    var remotePostsToReturnOnSyncPostsOfType = [RemotePost]()
    var remotePostToReturnOnUpdatePost: RemotePost?
    var remotePostToReturnOnCreatePost: RemotePost?
    var remotePostToReturnOnTrashPost: RemotePost?

    var autoSaveStubbedBehavior = StubbedBehavior.success(nil)

    // related to fetching likes
    var fetchLikesShouldSucceed: Bool = true
    var remoteUsersToReturnOnGetLikes = [RemoteLikeUser]()
    var totalLikes: NSNumber = 1

    private(set) var invocationsCountOfCreatePost = 0
    private(set) var invocationsCountOfAutoSave = 0
    private(set) var invocationsCountOfUpdate = 0

    override func getPostWithID(_ postID: NSNumber!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            success(self.remotePostToReturnOnGetPostWithID)
        }
    }

    override func getPostsOfType(_ postType: String!, options: [AnyHashable: Any]! = [:], success: (([RemotePost]?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            success(self.remotePostsToReturnOnSyncPostsOfType)
        }
    }

    override func update(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            self.invocationsCountOfUpdate += 1
            success(self.remotePostToReturnOnUpdatePost)
        }
    }

    override func createPost(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            self.invocationsCountOfCreatePost += 1
            success(self.remotePostToReturnOnCreatePost)
        }
    }

    override func trashPost(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            success(self.remotePostToReturnOnTrashPost)
        }
    }

    override func autoSave(_ post: RemotePost, success: ((RemotePost?, String?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            self.invocationsCountOfAutoSave += 1

            switch self.autoSaveStubbedBehavior {
            case .fail:
                failure(nil)
            case .success(let remotePost):
                success(remotePost, nil)
            }
        }
    }

    override func getLikesForPostID(_ postID: NSNumber,
                                    count: NSNumber,
                                    before: String?,
                                    excludeUserIDs: [NSNumber]?,
                                    success: (([RemoteLikeUser], NSNumber) -> Void)!,
                                    failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            if self.fetchLikesShouldSucceed {
                success(self.remoteUsersToReturnOnGetLikes, self.totalLikes)
            } else {
                failure(nil)
            }
        }
    }
}
