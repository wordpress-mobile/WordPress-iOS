import XCTest

@testable import WordPress

class BlogDashboardStateTests: CoreDataTestCase {
    private var dashboardState: BlogDashboardState!
    private var blog: Blog!

    override func setUp() {
        super.setUp()

        blog = BlogBuilder(contextManager.mainContext).build()
        dashboardState = BlogDashboardState.shared(for: blog)
    }

    /// `isFirstLoadFailure` is `true` when the dashboard failed to load
    /// and has not cached data
    ///
    func testIsFirstLoadFailureIsTrue() {
        dashboardState.failedToLoad = true
        dashboardState.hasCachedData = false

        XCTAssertTrue(dashboardState.isFirstLoadFailure)
    }

    /// `isFirstLoadFailure` is `false` when the dashboard failed to load
    /// but it has cached data
    ///
    func testIsFirstLoadFailureIsFalse() {
        dashboardState.failedToLoad = true
        dashboardState.hasCachedData = true

        XCTAssertFalse(dashboardState.isFirstLoadFailure)
    }

    /// `isFirstLoad` is `true` when the dashboard is loading
    /// for the first time
    ///
    func testisFirstLoadIsTrue() {
        dashboardState.failedToLoad = false
        dashboardState.hasCachedData = false

        XCTAssertTrue(dashboardState.isFirstLoad)
    }

    /// `isFirstLoad` is `false` when the dashboard is NOT loading
    /// for the first time
    ///
    func testisFirstLoadIsFalseWhenNotLoadingForFirstTime() {
        dashboardState.failedToLoad = false
        dashboardState.hasCachedData = true

        XCTAssertFalse(dashboardState.isFirstLoad)
    }

    /// `isFirstLoad` is `false` when the dashboard is in a
    /// failure state
    ///
    func testisFirstLoadIsFalseWhenInFailureState() {
        dashboardState.failedToLoad = true
        dashboardState.hasCachedData = false

        XCTAssertFalse(dashboardState.isFirstLoad)
    }

    /// Values should persist for the same blog
    ///
    func testValuesPersist() {
        blog.dashboardState.failedToLoad = false
        blog.dashboardState.hasCachedData = true

        XCTAssertFalse(blog.dashboardState.failedToLoad)
        XCTAssertTrue(blog.dashboardState.hasCachedData)
    }
}
