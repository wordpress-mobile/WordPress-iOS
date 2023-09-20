import Foundation
import XCTest

@testable import WordPress

/// Tests common and WPCom-only PostService behavior.
///
/// - SeeAlso: PostServiceSelfHostedTests
///
class PostServiceWPComTests: CoreDataTestCase {

    private let timeout: TimeInterval = 5
    private var remoteMock: PostServiceRESTMock!
    private var service: PostService!

    private let impossibleFailureBlock: (Error?) -> Void = { _ in
        assertionFailure("This shouldn't happen.")
    }

    override func setUp() {
        super.setUp()

        contextManager.useAsSharedInstance(untilTestFinished: self)

        remoteMock = PostServiceRESTMock()

        let remoteFactory = PostServiceRemoteFactoryMock()
        remoteFactory.remoteToReturn = remoteMock
        service = PostService(managedObjectContext: mainContext, postServiceRemoteFactory: remoteFactory)
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        remoteMock = nil
    }

    func testGettingANewPostFromTheAPIWillSetTheStatusAfterSyncProperty() {
        // Arrange
        let blog = BlogBuilder(mainContext).build()
        remoteMock.remotePostToReturnOnGetPostWithID = createRemotePost(.scheduled)
        let expectation = XCTestExpectation()

        // Act
        var post: AbstractPost?
        self.service.getPostWithID(123, for: blog, success: { postFromAPI in
            post = postFromAPI
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(post?.status, .scheduled)
        XCTAssertEqual(post?.statusAfterSync, .scheduled)
    }

    func testSyncingPostsWillSetTheStatusAfterSyncProperty() {
        // Arrange
        let blog = BlogBuilder(mainContext).build()
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [createRemotePost(.scheduled), createRemotePost(.publishPrivate)]
        let expectation = XCTestExpectation()

        // Act
        var posts: [AbstractPost]?
        self.service.syncPosts(ofType: .any, for: blog, success: { postsFromAPI in
            posts = postsFromAPI
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        let expectedStatuses: [BasePost.Status] = [.publishPrivate, .scheduled]

        XCTAssertEqual(posts?.count, 2)
        posts?.forEach { post in
            XCTAssertTrue(expectedStatuses.contains(post.status!))
            XCTAssertTrue(expectedStatuses.contains(post.statusAfterSync!))
            XCTAssertEqual(post.status, post.statusAfterSync)
        }
    }

    func testUpdatingAPostWillUpdateItsStatusAfterSyncProperty() {
        // Arrange
        let post = PostBuilder(mainContext).with(statusAfterSync: .publish).drafted().withRemote().build()
        try! mainContext.save()

        let remotePost = createRemotePost(.draft)
        remoteMock.remotePostToReturnOnUpdatePost = remotePost
        let expectation = XCTestExpectation()

        // Act
        var postFromAPI: AbstractPost?
        self.service.uploadPost(post, success: { aPost in
            postFromAPI = aPost
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertNotNil(postFromAPI)

        // Refetch from DB to make sure we're getting the updated data.
        let postFromDB = mainContext.object(with: postFromAPI!.objectID) as! AbstractPost
        // .draft is the status because it's what the returned RemotePost has
        XCTAssertEqual(postFromDB.statusAfterSync, .draft)
        XCTAssertEqual(postFromDB.status, .draft)
    }

    func testTrashingAPostWillUpdateItsRevisionStatusAfterSyncProperty() {
        // Arrange
        let post = PostBuilder(mainContext).with(statusAfterSync: .publish).withRemote().build()
        let revision = post.createRevision()
        try! mainContext.save()

        let remotePost = createRemotePost(.trash)
        remoteMock.remotePostToReturnOnTrashPost = remotePost
        let expectation = XCTestExpectation()

        // Act
        self.service.trashPost(post, success: {
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(post.statusAfterSync, .trash)
        XCTAssertEqual(post.status, .trash)
        XCTAssertEqual(revision.statusAfterSync, .trash)
        XCTAssertEqual(revision.status, .trash)
     }

    func testAutoSavingALocalDraftWillCallTheCreateEndpointInstead() {
        // Arrange
        let post = PostBuilder(mainContext).drafted().with(remoteStatus: .local).build()
        try! mainContext.save()

        remoteMock.remotePostToReturnOnCreatePost = createRemotePost(.draft)
        let expectation = XCTestExpectation()

        // Act
        self.service.autoSave(post, success: { _, _ in
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(self.remoteMock.invocationsCountOfCreatePost, 1)
        XCTAssertEqual(post.remoteStatus, .sync)
    }

    func testAutoSavingADraftWillCallTheUpdateEndpointInstead() {
        // Arrange
        let post = PostBuilder(mainContext).with(statusAfterSync: .draft).drafted().withRemote().build()
        try! mainContext.save()

        let remotePost = createRemotePost(.draft)
        remoteMock.remotePostToReturnOnUpdatePost = remotePost
        remoteMock.remotePostToReturnOnGetPostWithID = remotePost
        let expectation = XCTestExpectation()

        // Act
        self.service.autoSave(post, success: { _, _ in
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(self.remoteMock.invocationsCountOfUpdate, 1)
        XCTAssertEqual(post.remoteStatus, .sync)
    }

    /// Local drafts with `.published` status will be created on the server as a `.draft`.
    func testAutoSavingALocallyPublishedDraftWillCreateThePostAsADraft() {
        // Arrange
        let post = PostBuilder(mainContext).published().with(remoteStatus: .local).build()
        try! mainContext.save()

        remoteMock.remotePostToReturnOnCreatePost = createRemotePost(.draft)
        let expectation = XCTestExpectation()

        // Act
        self.service.autoSave(post, success: { _, _ in
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(self.remoteMock.invocationsCountOfCreatePost, 1)
        XCTAssertEqual(post.remoteStatus, .sync)
    }

    /// Local drafts with `.trash` status will not be automatically created on the server.
    func testAutoSavingALocallyTrashedPostWillFail() {
        // Arrange
        let post = PostBuilder(mainContext).trashed().with(remoteStatus: .local).build()
        try! mainContext.save()
        let expectation = XCTestExpectation()

        // Act
        var failureBlockCalled = false
        self.service.autoSave(post, success: { _, _ in
            expectation.fulfill()
        }, failure: { _ in
            failureBlockCalled = true
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertTrue(failureBlockCalled)
    }

    func testAutoSavingAnExistingPostWillCallTheAutoSaveEndpoint() {
        // Arrange
        let post = PostBuilder(mainContext).published().withRemote().with(remoteStatus: .sync).build()
        try! mainContext.save()

        remoteMock.autoSaveStubbedBehavior = .success(createRemotePost(.publish))
        let expectation = XCTestExpectation()

        // Act
        self.service.autoSave(post, success: { _, _ in
            expectation.fulfill()
        }, failure: self.impossibleFailureBlock)
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(self.remoteMock.invocationsCountOfAutoSave, 1)
        XCTAssertEqual(post.remoteStatus, .autoSaved)
    }

    func testAnAutoSaveFailureWillSetTheRemoteStatusToFailed() {
        // Arrange
        let post = PostBuilder(mainContext).published().withRemote().with(remoteStatus: .sync).build()
        try! mainContext.save()

        remoteMock.autoSaveStubbedBehavior = .fail
        let expectation = XCTestExpectation()

        // Act
        self.service.autoSave(post, success: { _, _ in
            expectation.fulfill()
        }, failure: { _ in
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: timeout)

        // Assert
        XCTAssertEqual(self.remoteMock.invocationsCountOfAutoSave, 1)
        XCTAssertEqual(post.remoteStatus, .failed)
    }

    func testFetchingPostLikesSuccessfullyShouldCallSuccessBlock() {
        // Arrange
        let postID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        let expectedUsers = [createRemoteLikeUser()]
        try! mainContext.save()
        remoteMock.remoteUsersToReturnOnGetLikes = expectedUsers
        let expectation = XCTestExpectation()

        // Act
        self.service.getLikesFor(postID: postID,
                                 siteID: siteID,
                                 success: { users, totalLikes, likesPerPage in
            // Assert
            XCTAssertEqual(users.count, 1)
            XCTAssertTrue(likesPerPage > 0)
            expectation.fulfill()
        },
                                 failure: { _ in
            XCTFail("This closure should not be called")
        })
        wait(for: [expectation], timeout: timeout)
    }

    func testFailingFetchPostLikesShouldCallFailureBlock() {
        // Arrange
        let postID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        try! mainContext.save()
        remoteMock.fetchLikesShouldSucceed = false
        let expectation = XCTestExpectation()

        // Act
        self.service.getLikesFor(postID: postID, siteID: siteID, success: { users, totalLikes, likesPerPage in
            XCTFail("this closure should not be called")
        },
                                 failure: { _ in
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: timeout)
    }

    /// The default `Post.authorID` value (currently 0 in the Core Data model) should
    /// be `nil` for `RemotePost`s.
    func testRemotePostAuthorIDNilForDefaultPostAuthorID() {
        // Given
        let post = PostBuilder(mainContext).build()
        try! mainContext.save()

        // When
        let remotePost = PostHelper.remotePost(with: post)

        // Then
        XCTAssertNil(remotePost.authorID)
    }

    /// `Post.authorID`s set to `nil` should be `nil` for `RemotePost`s.
    func testRemotePostAuthorIDNilForNilPostAuthorID() {
        // Given
        let post = PostBuilder(mainContext).build()
        post.authorID = nil
        try! mainContext.save()

        // When
        let remotePost = PostHelper.remotePost(with: post)

        // Then
        XCTAssertNil(remotePost.authorID)
    }

    /// `Post.authorID`s set to a valid value should be reflected in `RemotePost`s.
    func testRemotePostAuthorSetForValidPostAuthorID() {
        // Given
        let expectedAuthorID: NSNumber = 1
        let post = PostBuilder(mainContext).build()
        post.authorID = expectedAuthorID
        try! mainContext.save()

        // When
        let remotePost = PostHelper.remotePost(with: post)

        // Then
        XCTAssertEqual(remotePost.authorID, expectedAuthorID)
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
        success(self.remotePostToReturnOnGetPostWithID)
    }

    override func getPostsOfType(_ postType: String!, options: [AnyHashable: Any]! = [:], success: (([RemotePost]?) -> Void)!, failure: ((Error?) -> Void)!) {
        success(self.remotePostsToReturnOnSyncPostsOfType)
    }

    override func update(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        self.invocationsCountOfUpdate += 1
        success(self.remotePostToReturnOnUpdatePost)
    }

    override func createPost(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        self.invocationsCountOfCreatePost += 1
        success(self.remotePostToReturnOnCreatePost)
    }

    override func trashPost(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        success(self.remotePostToReturnOnTrashPost)
    }

    override func autoSave(_ post: RemotePost, success: ((RemotePost?, String?) -> Void)!, failure: ((Error?) -> Void)!) {
        self.invocationsCountOfAutoSave += 1

        switch self.autoSaveStubbedBehavior {
        case .fail:
            failure(nil)
        case .success(let remotePost):
            success(remotePost, nil)
        }
    }

    override func getLikesForPostID(_ postID: NSNumber,
                                    count: NSNumber,
                                    before: String?,
                                    excludeUserIDs: [NSNumber]?,
                                    success: (([RemoteLikeUser], NSNumber) -> Void)!,
                                    failure: ((Error?) -> Void)!) {
        if self.fetchLikesShouldSucceed {
            success(self.remoteUsersToReturnOnGetLikes, self.totalLikes)
        } else {
            failure(nil)
        }
    }
}
