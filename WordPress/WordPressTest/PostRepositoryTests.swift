import XCTest

@testable import WordPress

class PostRepositoryTests: CoreDataTestCase {

    private var remoteMock: PostServiceRESTMock!
    private var repository: PostRepository!
    private var blogID: TaggedManagedObjectID<Blog>!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let accountService = AccountService(coreDataStack: contextManager)
        let accountID = accountService.createOrUpdateAccount(withUsername: "username", authToken: "token")
        try accountService.setDefaultWordPressComAccount(XCTUnwrap(mainContext.existingObject(with: accountID) as? WPAccount))

        let blog = try BlogBuilder(mainContext).withAccount(id: accountID).build()

        contextManager.saveContextAndWait(mainContext)

        blogID = .init(blog)
        remoteMock = PostServiceRESTMock()
        let remoteFactory = PostServiceRemoteFactoryMock()
        remoteFactory.remoteToReturn = remoteMock
        repository = PostRepository(coreDataStack: contextManager, remoteFactory: remoteFactory)
    }

    func testGetPost() async throws {
        let post = RemotePost(siteID: 1, status: "publish", title: "Post: Test", content: "This is a test post")
        post?.type = "post"
        remoteMock.remotePostToReturnOnGetPostWithID = post
        let postID = try await repository.getPost(withID: 1, from: blogID)
        let isPage = try await contextManager.performQuery { try $0.existingObject(with: postID) is Page }
        let title = try await contextManager.performQuery { try $0.existingObject(with: postID).postTitle }
        let content = try await contextManager.performQuery { try $0.existingObject(with: postID).content }
        XCTAssertFalse(isPage)
        XCTAssertEqual(title, "Post: Test")
        XCTAssertEqual(content, "This is a test post")
    }

    func testGetPage() async throws {
        let post = RemotePost(siteID: 1, status: "publish", title: "Post: Test", content: "This is a test post")
        post?.type = "page"
        remoteMock.remotePostToReturnOnGetPostWithID = post
        let postID = try await repository.getPost(withID: 1, from: blogID)
        let isPage = try await contextManager.performQuery { try $0.existingObject(with: postID) is Page }
        let title = try await contextManager.performQuery { try $0.existingObject(with: postID).postTitle }
        let content = try await contextManager.performQuery { try $0.existingObject(with: postID).content }
        XCTAssertTrue(isPage)
        XCTAssertEqual(title, "Post: Test")
        XCTAssertEqual(content, "This is a test post")
    }

}

// These mock classes are copied from PostServiceWPComTests. We can't simply remove the `private` in the original class
// definition, because Xcode would complian about 'WordPress' module not found.

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
