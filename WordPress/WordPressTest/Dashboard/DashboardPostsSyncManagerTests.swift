import XCTest
@testable import WordPress

class DashboardPostsSyncManagerTests: CoreDataTestCase {

    private var blog: Blog!
    private let draftStatuses: [BasePost.Status] = [.draft, .pending]
    private let scheduledStatuses: [BasePost.Status] = [.scheduled]
    private var postService: PostServiceMock!
    private var blogService: BlogServiceMock!

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        blog = BlogBuilder(contextManager.mainContext).build()
        blog.dashboardState.postsSyncingStatuses = []
        blog.dashboardState.pagesSyncingStatuses = []
        postService = PostServiceMock()
        blogService = BlogServiceMock(coreDataStack: contextManager)
    }

    override func tearDown() {
        blog = nil
        super.tearDown()
    }

    func testSuccessfulPostsSync() {
        // Given
        let postsToReturn = [PostBuilder(contextManager.mainContext).build()]
        postService.syncShouldSucceed = true
        postService.returnSyncedPosts = postsToReturn

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertTrue(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSuccessfulPagesSync() {
        // Given
        let postsToReturn = [PostBuilder(contextManager.mainContext).build()]
        postService.syncShouldSucceed = true
        postService.returnSyncedPosts = postsToReturn

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .page, statuses: draftStatuses)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .page)
        XCTAssertEqual(blog.dashboardState.pagesSyncingStatuses, [])
        XCTAssertTrue(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testFailingPostsSync() {
        // Given
        postService.syncShouldSucceed = false

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertTrue(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testNotSyncingIfAnotherSyncinProgress() {
        // Given
        postService.syncShouldSucceed = false
        blog.dashboardState.postsSyncingStatuses = draftStatuses

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)

        // Then
        XCTAssertFalse(listener.postsSyncedCalled)
        XCTAssertFalse(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSyncingPostsIfSomeStatusesAreNotBeingSynced() {
        // Given
        postService.syncShouldSucceed = false
        blog.dashboardState.postsSyncingStatuses = draftStatuses

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        let toBeSynced = draftStatuses + scheduledStatuses
        manager.syncPosts(blog: blog, postType: .post, statuses: toBeSynced)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(listener.statusesSynced, scheduledStatuses)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, draftStatuses)
        XCTAssertTrue(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSuccessfulSyncAfterAuthorsSync() {
        // Given
        postService.syncShouldSucceed = true
        blogService.syncShouldSucceed = true
        blog.userID = nil
        blog.isAdmin = true

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)


        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertTrue(blogService.syncAuthorsCalled)
        XCTAssertTrue(postService.syncPostsCalled)
    }

    func testFailingAuthorsSync() {
        // Given
        postService.syncShouldSucceed = true
        blogService.syncShouldSucceed = false
        blog.userID = nil
        blog.isAdmin = true

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
        XCTAssertTrue(blogService.syncAuthorsCalled)
        XCTAssertFalse(postService.syncPostsCalled)
    }

}

class SyncManagerListenerMock: DashboardPostsSyncManagerListener {

    var postsSyncedCalled = false
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
