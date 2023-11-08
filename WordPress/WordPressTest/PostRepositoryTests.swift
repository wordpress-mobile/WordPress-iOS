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

    func testDeletePost() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).with(status: .trash).withRemote().with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        remoteMock.deletePostResult = .success(())
        try await repository.delete(postID)

        let isPostDeleted = await contextManager.performQuery { context in
            (try? context.existingObject(with: postID)) == nil
        }
        XCTAssertTrue(isPostDeleted)
    }

    func testDeletePostWithRemoteFailure() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).with(status: .trash).withRemote().with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        remoteMock.deletePostResult = .failure(NSError.testInstance())
        do {
            try await repository.delete(postID)
            XCTFail("The deletion should fail because of an API failure")
        } catch {
            // Do nothing
        }

        let isPostDeleted = await contextManager.performQuery { context in
            (try? context.existingObject(with: postID)) == nil
        }
        XCTAssertTrue(isPostDeleted)
    }

    func testDeleteHistory() async throws {
        let (firstRevision, secondRevision) = try await contextManager.performAndSave { context in
            let first = PostBuilder(context).with(status: .trash).withRemote().with(title: "Post: Test").build()
            let second = first.createRevision()
            second.postTitle = "Edited"
            return (TaggedManagedObjectID(first), TaggedManagedObjectID(second))
        }

        remoteMock.deletePostResult = .success(())
        try await repository.delete(firstRevision)

        let isPostDeleted = await contextManager.performQuery { context in
            (try? context.existingObject(with: firstRevision)) == nil
              && (try? context.existingObject(with: secondRevision)) == nil
        }
        XCTAssertTrue(isPostDeleted)
    }

    func testDeleteLatest() async throws {
        let (firstRevision, secondRevision) = try await contextManager.performAndSave { context in
            let first = PostBuilder(context).with(status: .trash).withRemote().with(title: "Post: Test").build()
            let second = first.createRevision()
            second.postTitle = "Edited"
            return (TaggedManagedObjectID(first), TaggedManagedObjectID(second))
        }

        remoteMock.deletePostResult = .success(())
        try await repository.delete(secondRevision)

        let isPostDeleted = await contextManager.performQuery { context in
            (try? context.existingObject(with: firstRevision)) == nil
              && (try? context.existingObject(with: secondRevision)) == nil
        }
        XCTAssertTrue(isPostDeleted)
    }

    func testTrashPost() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).withRemote().with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        // No API call should be made, because the post is a local post
        let remotePost = RemotePost(siteID: 1, status: "trash", title: "Post: Test", content: "New content")!
        remotePost.type = "post"
        remoteMock.trashPostResult = .success(remotePost)
        try await repository.trash(postID)

        let content = try await contextManager.performQuery { context in
            (try context.existingObject(with: postID)).content
        }
        XCTAssertEqual(content, "New content")
    }

    func testTrashLocalPost() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        // No API call should be made, because the post is a local post
        remoteMock.trashPostResult = .failure(NSError.testInstance())
        try await repository.trash(postID)

        let status = try await contextManager.performQuery { context in
            (try context.existingObject(with: postID)).status
        }
        XCTAssertEqual(status, .trash)
    }

    func testTrashTrashedPost() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).with(status: .trash).with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        // No API call should be made, because the post is a local post
        remoteMock.trashPostResult = .failure(NSError.testInstance())
        remoteMock.deletePostResult = .failure(NSError.testInstance())
        try await repository.trash(postID)

        let isPostDeleted = await contextManager.performQuery { context in
            (try? context.existingObject(with: postID)) == nil
        }
        XCTAssertTrue(isPostDeleted)
    }

    func testTrashingAPostWillUpdateItsRevisionStatusAfterSyncProperty() async throws {
        // Arrange
        let (postID, revisionID) = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).with(statusAfterSync: .publish).withRemote().build()
            let revision = post.createRevision()
            return (TaggedManagedObjectID(post), TaggedManagedObjectID(revision))
        }

        let remotePost = RemotePost(siteID: 1, status: "trash", title: "Post: Test", content: "New content")!
        remotePost.type = "post"
        remoteMock.trashPostResult = .success(remotePost)

        // Act
        try await repository.trash(postID)

        // Assert
        let postStatusAfterSync = try await contextManager.performQuery { try $0.existingObject(with: postID).statusAfterSync }
        let postStatus = try await contextManager.performQuery { try $0.existingObject(with: postID).status }
        let revisionStatusAfterSync = try await contextManager.performQuery { try $0.existingObject(with: revisionID).statusAfterSync }
        let revisionStatus = try await contextManager.performQuery { try $0.existingObject(with: revisionID).status }

        XCTAssertEqual(postStatusAfterSync, .trash)
        XCTAssertEqual(postStatus, .trash)
        XCTAssertEqual(revisionStatusAfterSync, .trash)
        XCTAssertEqual(revisionStatus, .trash)
     }

    func testRestorePost() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).withRemote().with(status: .trash).with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        let remotePost = RemotePost(siteID: 1, status: "draft", title: "Post: Test", content: "New content")!
        remotePost.type = "post"
        remoteMock.restorePostResult = .success(remotePost)
        try await repository.restore(postID, to: .publish)

        // The restored post should match the post returned by WordPress API.
        let (status, content) = try await contextManager.performQuery { context in
            let post = try context.existingObject(with: postID)
            return (post.status, post.content)
        }
        XCTAssertEqual(status, .draft)
        XCTAssertEqual(content, "New content")
    }

    func testRestorePostFailure() async throws {
        let postID = try await contextManager.performAndSave { context in
            let post = PostBuilder(context).withRemote().with(status: .trash).with(title: "Post: Test").build()
            return TaggedManagedObjectID(post)
        }

        remoteMock.restorePostResult = .failure(NSError.testInstance())

        do {
            try await repository.restore(postID, to: .publish)
            XCTFail("The restore call should throw an error")
        } catch {
            let status = try await contextManager.performQuery { context in
                let post = try context.existingObject(with: postID)
                return post.status
            }
            XCTAssertEqual(status, .trash)
        }
    }

    func testFetchAllPagesAPIError() async throws {
        // Use an empty array to simulate an HTTP API error
        remoteMock.remotePostsToReturnOnSyncPostsOfType = []

        do {
            let _ = try await repository.fetchAllPages(statuses: [], in: blogID).value
            XCTFail("The above call should throw")
        } catch {
            // Do nothing.
        }
    }

    func testFetchAllPagesStopsOnEmptyAPIResponse() async throws {
        // Given two pages of API result: first page returns 100 page instances, and the second page returns an empty result.
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [
            try (1...100).map {
                let post = try XCTUnwrap(RemotePost(siteID: NSNumber(value: $0), status: "publish", title: "Post: Test", content: "This is a test post"))
                post.type = "page"
                return post
            },
            []
        ]

        let pages = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(pages.count, 100)
    }

    func testFetchAllPagesStopsOnNonFullPageAPIResponse() async throws {
        // Given two pages of API result: first page returns 100 page instances, and the second page returns 10 (any amount that's less than 100) page instances.
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [
            try (1...100).map {
                let post = try XCTUnwrap(RemotePost(siteID: NSNumber(value: $0), status: "publish", title: "Post: Test", content: "This is a test post"))
                post.type = "page"
                return post
            },
            try (1...10).map {
                let post = try XCTUnwrap(RemotePost(siteID: NSNumber(value: $0), status: "publish", title: "Post: Test", content: "This is a test post"))
                post.type = "page"
                return post
            },
        ]

        let pages = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(pages.count, 110)
    }

    func testCancelFetchAllPages() async throws {
        remoteMock.remotePostsToReturnOnSyncPostsOfType = try (1...10).map { pageNo in
            try (1...100).map {
                let post = try XCTUnwrap(RemotePost(siteID: NSNumber(value: pageNo * 100 + $0), status: "publish", title: "Post: Test", content: "This is a test post"))
                post.type = "page"
                return post
            }
        }

        let cancelled = expectation(description: "Fetching task returns cancellation error")
        let task = repository.fetchAllPages(statuses: [.publish], in: blogID)

        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(100)) {
            task.cancel()
        }

        do {
            let _ = try await task.value
        } catch is CancellationError {
            cancelled.fulfill()
        }

        await fulfillment(of: [cancelled], timeout: 0.3)
    }

    func testFetchTwoFullPages() async throws {
        // 300 pages of API result
        remoteMock.remotePostsToReturnOnSyncPostsOfType = try (1...2).map { pageNo in
            try (1...100).map {
                let post = try XCTUnwrap(RemotePost(siteID: NSNumber(value: pageNo * 1000 + $0), status: "publish", title: "Post: Test", content: "This is a test post"))
                post.type = "page"
                return post
            }
        } + [[]]

        let allPages = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(allPages.count, 15_000)
    }

    func testFetchManyManyPages() async throws {
        // 90 pages of API result
        remoteMock.remotePostsToReturnOnSyncPostsOfType = try (1...99).map { pageNo in
            try (1...100).map {
                let post = try XCTUnwrap(RemotePost(siteID: NSNumber(value: pageNo * 1000 + $0), status: "publish", title: "Post: Test", content: "This is a test post"))
                post.type = "page"
                return post
            }
        } + [[]]

        let allPages = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(allPages.count, 9_900)
    }

    func testFetchAllPagesPurgesDeletedPages() async throws {
        let postToBeKept = try XCTUnwrap(RemotePost(siteID: 1, status: "publish", title: "Post: Kept", content: "This is a test post"))
        postToBeKept.postID = 100
        postToBeKept.type = "page"
        let postToBeDeleted = try XCTUnwrap(RemotePost(siteID: 1, status: "publish", title: "Post: Deleted", content: "This is a test post"))
        postToBeDeleted.postID = 200
        postToBeDeleted.type = "page"

        // The first fetch returns both page instances.
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [
            [postToBeKept, postToBeDeleted],
        ]
        let firstFetch = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(firstFetch.count, 2)
        try await contextManager.performQuery { context in
            let first = try context.existingObject(with: XCTUnwrap(firstFetch.first))
            let second = try context.existingObject(with: XCTUnwrap(firstFetch.last))
            XCTAssertEqual(first.postID, 100)
            XCTAssertEqual(second.postID, 200)
        }

        // The second fetch only returns one of them, to simulate an situation where the other page has been deleted from the site.
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [
            [postToBeKept],
        ]
        let secondFetch = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(secondFetch.count, 1)
        try await contextManager.performQuery { context in
            let page = try context.existingObject(with: XCTUnwrap(firstFetch.first))
            XCTAssertEqual(page.postID, postToBeKept.postID)
        }
    }

    func testFetchAllPagesKeepPagesWithOtherStatus() async throws {
        let remotePage = try XCTUnwrap(RemotePost(siteID: 1, status: "publish", title: "Post: Kept", content: "This is a test post"))
        remotePage.postID = 100
        remotePage.type = "page"

        // The first fetch returns a published post
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [[remotePage]]
        let firstFetch = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        try await contextManager.performQuery { context in
            let page = try context.existingObject(with: XCTUnwrap(firstFetch.first))
            XCTAssertEqual(page.postID, remotePage.postID)
        }

        // The second fetch returns empty result, because there is no draft on the site
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [[]]
        let secondFetch = try await repository.fetchAllPages(statuses: [.draft], in: blogID).value
        XCTAssertTrue(secondFetch.isEmpty)

        let pageExists = await contextManager.performQuery { context in
            (try? context.existingObject(with: XCTUnwrap(firstFetch.first))) != nil
        }
        XCTAssertTrue(pageExists, "The previously fetched published pages is not deleted by the draft pages fetching request")
    }

    func testFetchAllPagesKeepLocalEdits() async throws {
        let remotePage = try XCTUnwrap(RemotePost(siteID: 1, status: "publish", title: "Post: Kept", content: "This is a test post"))
        remotePage.postID = 100
        remotePage.type = "page"
        remoteMock.remotePostsToReturnOnSyncPostsOfType = [[remotePage], [remotePage]]

        // The first fetch returns a published post
        let firstFetch = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        try await contextManager.performQuery { context in
            let page = try context.existingObject(with: XCTUnwrap(firstFetch.first))
            XCTAssertEqual(page.postID, remotePage.postID)
        }

        // Edit the fetched page.
        let localEditID = try await contextManager.performAndSave { context in
            let page = try context.existingObject(with: XCTUnwrap(firstFetch.first))
            let localEdit = page.createRevision()
            localEdit.postTitle = "Changes changes and changes"
            return TaggedManagedObjectID(localEdit)
        }

        // The second fetch returns the same result as the previous one.
        let secondFetch = try await repository.fetchAllPages(statuses: [.publish], in: blogID).value
        XCTAssertEqual(firstFetch, secondFetch)

        try await contextManager.performQuery { context in
            let localEdit = try context.existingObject(with: localEditID)
            XCTAssertNotNil(localEdit.original)
            try XCTAssertEqual(XCTUnwrap(localEdit.original).objectID, XCTUnwrap(secondFetch.first).objectID)
        }
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
    var remotePostsToReturnOnSyncPostsOfType = [[RemotePost]]() // Each element contains an array of RemotePost for one API request.
    var remotePostToReturnOnUpdatePost: RemotePost?
    var remotePostToReturnOnCreatePost: RemotePost?

    var autoSaveStubbedBehavior = StubbedBehavior.success(nil)

    // related to fetching likes
    var fetchLikesShouldSucceed: Bool = true
    var remoteUsersToReturnOnGetLikes = [RemoteLikeUser]()
    var totalLikes: NSNumber = 1

    var deletePostResult: Result<Void, Error> = .success(())
    var trashPostResult: Result<RemotePost, Error> = .failure(NSError.testInstance())
    var restorePostResult: Result<RemotePost, Error> = .failure(NSError.testInstance())

    private(set) var invocationsCountOfCreatePost = 0
    private(set) var invocationsCountOfAutoSave = 0
    private(set) var invocationsCountOfUpdate = 0

    override func getPostWithID(_ postID: NSNumber!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        success(self.remotePostToReturnOnGetPostWithID)
    }

    override func getPostsOfType(_ postType: String!, options: [AnyHashable: Any]! = [:], success: (([RemotePost]?) -> Void)!, failure: ((Error?) -> Void)!) {
        guard !remotePostsToReturnOnSyncPostsOfType.isEmpty else {
            failure(testError())
            return
        }

        let result = remotePostsToReturnOnSyncPostsOfType.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(50)) {
            success(result)
        }
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
        switch self.trashPostResult {
        case let .failure(error):
            failure(error)
        case let .success(remotePost):
            success(remotePost)
        }
    }

    override func restore(_ post: RemotePost!, success: ((RemotePost?) -> Void)!, failure: ((Error?) -> Void)!) {
        switch self.restorePostResult {
        case let .failure(error):
            failure(error)
        case let .success(remotePost):
            success(remotePost)
        }
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

    override func delete(_ post: RemotePost!, success: (() -> Void)!, failure: ((Error?) -> Void)!) {
        switch deletePostResult {
        case let .failure(error):
            failure(error)
        case .success:
            success()
        }
    }
}
