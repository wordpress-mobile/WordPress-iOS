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
        blog.dashboardState.syncingStatuses = []
        postService = PostServiceMock()
        blogService = BlogServiceMock(managedObjectContext: contextManager.mainContext)
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
        manager.syncPosts(blog: blog, statuses: draftStatuses.strings)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.postsSynced, postsToReturn)
        XCTAssertEqual(blog.dashboardState.syncingStatuses, [])
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
        manager.syncPosts(blog: blog, statuses: draftStatuses.strings)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(blog.dashboardState.syncingStatuses, [])
        XCTAssertTrue(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testNotSyncingIfAnotherSyncinProgress() {
        // Given
        postService.syncShouldSucceed = false
        blog.dashboardState.syncingStatuses = draftStatuses.strings

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        manager.syncPosts(blog: blog, statuses: draftStatuses.strings)

        // Then
        XCTAssertFalse(listener.postsSyncedCalled)
        XCTAssertFalse(postService.syncPostsCalled)
        XCTAssertFalse(blogService.syncAuthorsCalled)
    }

    func testSyncingPostsIfSomeStatusesAreNotBeingSynced() {
        // Given
        postService.syncShouldSucceed = false
        blog.dashboardState.syncingStatuses = draftStatuses.strings

        let manager = DashboardPostsSyncManager(postService: postService, blogService: blogService)
        let listener = SyncManagerListenerMock()
        manager.addListener(listener)

        // When
        let toBeSynced = draftStatuses.strings + scheduledStatuses.strings
        manager.syncPosts(blog: blog, statuses: toBeSynced)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(listener.statusesSynced, scheduledStatuses.strings)
        XCTAssertEqual(blog.dashboardState.syncingStatuses, draftStatuses.strings)
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
        manager.syncPosts(blog: blog, statuses: draftStatuses.strings)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertTrue(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(blog.dashboardState.syncingStatuses, [])
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
        manager.syncPosts(blog: blog, statuses: draftStatuses.strings)

        // Then
        XCTAssertTrue(listener.postsSyncedCalled)
        XCTAssertFalse(listener.postsSyncSuccess ?? false)
        XCTAssertEqual(listener.postsSyncBlog, blog)
        XCTAssertEqual(blog.dashboardState.syncingStatuses, [])
        XCTAssertTrue(blogService.syncAuthorsCalled)
        XCTAssertFalse(postService.syncPostsCalled)
    }

}

class BlogServiceMock: BlogService {

    var syncAuthorsCalled = false

    var syncShouldSucceed = true

    override func syncAuthors(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        syncAuthorsCalled = true
        if syncShouldSucceed {
            blog.userID = 1
            success()
        }
        else {
            let error = NSError(domain: "", code: 0)
            failure(error)
        }

    }
}

class SyncManagerListenerMock: DashboardPostsSyncManagerListener {

    var postsSyncedCalled = false
    var postsSyncSuccess: Bool?
    var postsSyncBlog: Blog?
    var postsSynced: [AbstractPost]?
    var statusesSynced: [String]?

    func postsSynced(success: Bool, blog: Blog, posts: [AbstractPost]?, for statuses: [String]) {
        self.postsSyncedCalled = true
        self.postsSyncSuccess = success
        self.postsSyncBlog = blog
        self.postsSynced = posts
        self.statusesSynced = statuses
    }
}
