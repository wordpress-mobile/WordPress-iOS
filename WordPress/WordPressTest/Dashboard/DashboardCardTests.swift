import XCTest
@testable import WordPress

class MockDefaultSectionProvider: DefaultSectionProvider {
    var defaultSection: MySiteViewController.Section

    init(defaultSection: MySiteViewController.Section) {
        self.defaultSection = defaultSection
    }
}

class DashboardCardTests: XCTestCase {

    // MARK: Quick Start

    func testShouldShowQuickStartIfEnabledAndDefaultSectionIsDashboard() {
        // Given
        let mySiteSettings = MockDefaultSectionProvider(defaultSection: .dashboard)
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        QuickStartTourGuide.shared.setup(for: blog)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog, mySiteSettings: mySiteSettings)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowQuickStartIfDefaultSectionIsSiteMenu() {
        // Given
        let mySiteSettings = MockDefaultSectionProvider(defaultSection: .siteMenu)
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        QuickStartTourGuide.shared.setup(for: blog)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog, mySiteSettings: mySiteSettings)

        // Then
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowQuickStartIfDisabled() {
        // Given
        let mySiteSettings = MockDefaultSectionProvider(defaultSection: .dashboard)
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        QuickStartTourGuide.shared.setup(for: blog)
        QuickStartTourGuide.shared.remove(from: blog)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog, mySiteSettings: mySiteSettings)

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: Stats

    func testShouldShowStatsCardWhenResponseIsAvaialble() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let apiResponse = buildEntity(hasDrafts: true, hasScheduled: false, hasPublished: false)

        // When
        let shouldShow = DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowStatsCardIfResponseIsUnavailable() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()

        // When
        let shouldShow = DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: nil)

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: Ghost

    func testShouldShowGhostCardOnFirstLoad() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let dashboardState = BlogDashboardState.shared(for: blog)
        dashboardState.hasCachedData = false
        dashboardState.failedToLoad = false

        // When
        let shouldShow = DashboardCard.ghost.shouldShow(for: blog)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowGhostCardIfLoaded() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let dashboardState = BlogDashboardState.shared(for: blog)
        dashboardState.hasCachedData = true
        dashboardState.failedToLoad = false

        // When
        let shouldShow = DashboardCard.ghost.shouldShow(for: blog)

        // Then
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowGhostCardIfFailedToLoad() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let dashboardState = BlogDashboardState.shared(for: blog)
        dashboardState.hasCachedData = false
        dashboardState.failedToLoad = true

        // When
        let shouldShow = DashboardCard.ghost.shouldShow(for: blog)

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: Failure

    func testShouldShowFailureCardOnFirstLoadFailure() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let dashboardState = BlogDashboardState.shared(for: blog)
        dashboardState.hasCachedData = false
        dashboardState.failedToLoad = true

        // When
        let shouldShow = DashboardCard.failure.shouldShow(for: blog)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowFailureCardIfSecondLoadFailed() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let dashboardState = BlogDashboardState.shared(for: blog)
        dashboardState.hasCachedData = true
        dashboardState.failedToLoad = true

        // When
        let shouldShow = DashboardCard.failure.shouldShow(for: blog)

        // Then
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowFailureCardIfLoaded() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let dashboardState = BlogDashboardState.shared(for: blog)
        dashboardState.hasCachedData = true
        dashboardState.failedToLoad = false

        // When
        let shouldShow = DashboardCard.failure.shouldShow(for: blog)

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: Posts

    func testShowingDraftsCardOnly() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let apiResponse = buildEntity(hasDrafts: true, hasScheduled: false, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowNextPost = DashboardCard.nextPost.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowCreatePost = DashboardCard.createPost.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShowDrafts)
        XCTAssertFalse(shouldShowScheduled)
        XCTAssertFalse(shouldShowNextPost)
        XCTAssertFalse(shouldShowCreatePost)
    }

    func testShowingScheduledCardOnly() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let apiResponse = buildEntity(hasDrafts: false, hasScheduled: true, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowNextPost = DashboardCard.nextPost.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowCreatePost = DashboardCard.createPost.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertFalse(shouldShowDrafts)
        XCTAssertTrue(shouldShowScheduled)
        XCTAssertFalse(shouldShowNextPost)
        XCTAssertFalse(shouldShowCreatePost)
    }

    func testShowingDraftsAndScheduled() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let apiResponse = buildEntity(hasDrafts: true, hasScheduled: true, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowNextPost = DashboardCard.nextPost.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowCreatePost = DashboardCard.createPost.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShowDrafts)
        XCTAssertTrue(shouldShowScheduled)
        XCTAssertFalse(shouldShowNextPost)
        XCTAssertFalse(shouldShowCreatePost)
    }

    func testShowingNextPostCardOnly() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let apiResponse = buildEntity(hasDrafts: false, hasScheduled: false, hasPublished: true)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowNextPost = DashboardCard.nextPost.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowCreatePost = DashboardCard.createPost.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertFalse(shouldShowDrafts)
        XCTAssertFalse(shouldShowScheduled)
        XCTAssertTrue(shouldShowNextPost)
        XCTAssertFalse(shouldShowCreatePost)
    }

    func testShowingCreatePostCardOnly() {
        // Given
        let blog = BlogBuilder(TestContextManager().mainContext).build()
        let apiResponse = buildEntity(hasDrafts: false, hasScheduled: false, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowNextPost = DashboardCard.nextPost.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowCreatePost = DashboardCard.createPost.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertFalse(shouldShowDrafts)
        XCTAssertFalse(shouldShowScheduled)
        XCTAssertFalse(shouldShowNextPost)
        XCTAssertTrue(shouldShowCreatePost)
    }

    // MARK: Remote Cards

    func testRemoteCardsIdentifiers() {
        // When
        let identifiers = DashboardCard.RemoteDashboardCard.allCases.map { $0.rawValue }

        // Then
        XCTAssertEqual(identifiers, ["todays_stats", "posts"])
    }

    // MARK: Helpers

    private func buildEntity(hasDrafts: Bool, hasScheduled: Bool, hasPublished: Bool) -> BlogDashboardRemoteEntity {
        let drafts = hasDrafts ? [BlogDashboardRemoteEntity.BlogDashboardPosts.BlogDashboardPost()] : []
        let scheduled = hasScheduled ? [BlogDashboardRemoteEntity.BlogDashboardPosts.BlogDashboardPost()] : []
        let posts = BlogDashboardRemoteEntity.BlogDashboardPosts(hasPublished: hasPublished, draft: drafts, scheduled: scheduled)
        return BlogDashboardRemoteEntity(posts: posts, todaysStats: nil)
    }

}
