import XCTest
@testable import WordPress

class DashboardPostsSyncManagerTests: CoreDataTestCase {

    private var blog: Blog!
    private var blogID: TaggedManagedObjectID<Blog>!
    private let draftStatuses: [BasePost.Status] = [.draft, .pending]
    private let scheduledStatuses: [BasePost.Status] = [.scheduled]
    private var postRepository: PostRepository!
    private var blogService: BlogServiceMock!

    override func setUp() async throws {
        try await super.setUp()

        let account = AccountService(coreDataStack: contextManager).createOrUpdateAccount(withUsername: "username", authToken: "token")
        blogID = try await contextManager.performAndSave {
            let blog = try BlogBuilder($0).withAccount(id: account).with(dotComID: 42).build()
            blog.dashboardState.postsSyncingStatuses = []
            blog.dashboardState.pagesSyncingStatuses = []
            return TaggedManagedObjectID(blog)
        }

        try await mainContext.perform {
            self.blog = try self.mainContext.existingObject(with: self.blogID)
        }

        postRepository = PostRepository(coreDataStack: contextManager)
        blogService = BlogServiceMock(coreDataStack: contextManager)
    }

    override func tearDown() {
        blog = nil
        super.tearDown()
    }

    func testSuccessfulPostsSync() {
        // Given
        stubGetPostsList(type: "post", total: 50)

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)
        wait(for: [expectation(that: \.postsSyncedCalled, on: listener, willEqual: true)], timeout: 0.1)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSuccessfulPagesSync() {
        // Given
        stubGetPostsList(type: "page", total: 50)

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .page, statuses: draftStatuses)
        wait(for: [expectation(that: \.postsSyncedCalled, on: listener, willEqual: true)], timeout: 0.1)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .page)
        XCTAssertEqual(blog.dashboardState.pagesSyncingStatuses, [])
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testFailingPostsSync() {
        // Given
        stubGetPostsListWithServerError()

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)
        wait(for: [expectation(that: \.postsSyncedCalled, on: listener, willEqual: true)], timeout: 0.1)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testNotSyncingIfAnotherSyncinProgress() {
        // Given
        blog.dashboardState.postsSyncingStatuses = draftStatuses

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)
        // Then
        XCTAssertFalse(listener.postsSyncedCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSyncingPostsIfSomeStatusesAreNotBeingSynced() {
        // Given
        stubGetPostsListWithServerError()
        blog.dashboardState.postsSyncingStatuses = draftStatuses

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        let toBeSynced = draftStatuses + scheduledStatuses
        manager.syncPosts(blog: blog, postType: .post, statuses: toBeSynced)
        wait(for: [expectation(that: \.postsSyncedCalled, on: listener, willEqual: true)], timeout: 0.1)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(listener.statusesSynced, scheduledStatuses)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, draftStatuses)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSuccessfulSyncAfterAuthorsSync() {
        // Given
        stubGetPostsList(type: "post", total: 50)
        blogService.syncShouldSucceed = true
        blog.userID = nil
        blog.isAdmin = true

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)


        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)
        wait(for: [expectation(that: \.postsSyncedCalled, on: listener, willEqual: true)], timeout: 0.1)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertTrue(blogService.syncAuthorsCalled)
    }

    func testFailingAuthorsSync() {
        // Given
        stubGetPostsList(type: "post", total: 50)
        blogService.syncShouldSucceed = false
        blog.userID = nil
        blog.isAdmin = true

        let manager = DashboardPostsSyncManager(postRepository: postRepository, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)
        wait(for: [expectation(that: \.postsSyncedCalled, on: listener, willEqual: true)], timeout: 0.1)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertTrue(blogService.syncAuthorsCalled)
    }

}

class SyncManagerListenerMock: NSObject, DashboardPostsSyncManagerListener {

    @objc dynamic var postsSyncedCalled = false
    var postsSyncSuccess: Bool?
    var postsSyncBlog: Blog?
    var postsSyncType: DashboardPostsSyncManager.PostType?
    var statusesSynced: [BasePost.Status]?

    func postsSynced(success: Bool,
                     blog: Blog,
                     postType: DashboardPostsSyncManager.PostType,
                     for statuses: [BasePost.Status]) {
        self.postsSyncedCalled = true
        self.postsSyncSuccess = success
        self.postsSyncBlog = blog
        self.postsSyncType = postType
        self.statusesSynced = statuses
    }
}
