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

    func testSuccessfulSync() {
        // Given
        let postsToReturn = [PostBuilder(contextManager.mainContext).build()]
        postService.syncShouldSucceed = true
        postService.returnSyncedPosts = postsToReturn

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses.strings)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(listener.postsSynced, postsToReturn)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, [])
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
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses.strings)

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
        blog.dashboardState.postsSyncingStatuses = draftStatuses.strings

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses.strings)

        // Then
        XCTAssertFalse(listener.postsSyncedCalled)
        XCTAssertFalse(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSyncingPostsIfSomeStatusesAreNotBeingSynced() {
        // Given
        postService.syncShouldSucceed = false
        blog.dashboardState.postsSyncingStatuses = draftStatuses.strings

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        let toBeSynced = draftStatuses.strings + scheduledStatuses.strings
        manager.syncPosts(blog: blog, postType: .post, statuses: toBeSynced)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSyncType, .post)
        XCTAssertEqual(listener.statusesSynced, scheduledStatuses.strings)
        XCTAssertEqual(blog.dashboardState.postsSyncingStatuses, draftStatuses.strings)
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
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses.strings)

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
        manager.syncPosts(blog: blog, postType: .post, statuses: draftStatuses.strings)

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
    var postsSynced: [AbstractPost]?
    var statusesSynced: [String]?

    func postsSynced(success: Bool,
                     blog: Blog,
                     postType: DashboardPostsSyncManager.PostType,
                     posts: [AbstractPost]?,
                     for statuses: [String]) {
        self.postsSyncedCalled = true
        self.postsSyncSuccess = success
        self.postsSyncBlog = blog
        self.postsSyncType = postType
        self.postsSynced = posts
        self.statusesSynced = statuses
    }
}
