import XCTest
@testable import WordPress

class DashboardCardTests: CoreDataTestCase {

    private var blog: Blog!
    private let featureFlags = FeatureFlagOverrideStore()

    override func setUp() {
        super.setUp()

        contextManager.useAsSharedInstance(untilTestFinished: self)
        blog = BlogBuilder(mainContext).withAnAccount().build()
        blog.isAdmin = true
        try? featureFlags.override(RemoteFeatureFlag.activityLogDashboardCard, withValue: true)
        try? featureFlags.override(RemoteFeatureFlag.pagesDashboardCard, withValue: true)
    }

    override func tearDown() {
        QuickStartTourGuide.shared.remove(from: blog)
        blog = nil
        try? featureFlags.override(RemoteFeatureFlag.activityLogDashboardCard, withValue: RemoteFeatureFlag.activityLogDashboardCard.originalValue)
        try? featureFlags.override(RemoteFeatureFlag.pagesDashboardCard, withValue: RemoteFeatureFlag.pagesDashboardCard.originalValue)
        super.tearDown()
    }

    // MARK: Quick Start

    func testShouldShowQuickStartIfEnabledAndDefaultSectionIsDashboard() {
        // Given
        QuickStartTourGuide.shared.setup(for: blog, type: .newSite)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowQuickStartIfDisabled() {
        // Given
        QuickStartTourGuide.shared.setup(for: blog, type: .newSite)
        QuickStartTourGuide.shared.remove(from: blog)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog)

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: Stats

    func testShouldShowStatsCard() {
        // Given
        let apiResponse = buildEntity(hasStats: true)

        // When
        let shouldShow = DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowStatsCard() {
        // Given
        let apiResponse = buildEntity(hasStats: false)

        // When
        let shouldShow = DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertFalse(shouldShow)
    }

    // MARK: Ghost

    func testShouldShowGhostCardOnFirstLoad() {
        // Given
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
        let apiResponse = buildEntity(hasDrafts: true, hasScheduled: false, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShowDrafts)
        XCTAssertFalse(shouldShowScheduled)
    }

    func testShowingScheduledCardOnly() {
        // Given
        let apiResponse = buildEntity(hasDrafts: false, hasScheduled: true, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertFalse(shouldShowDrafts)
        XCTAssertTrue(shouldShowScheduled)
    }

    func testShowingDraftsAndScheduled() {
        // Given
        let apiResponse = buildEntity(hasDrafts: true, hasScheduled: true, hasPublished: false)

        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: apiResponse)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShowDrafts)
        XCTAssertTrue(shouldShowScheduled)
    }

    // MARK: Pages

    func testShowingPagesCardWhenThereArePages() {
        // Given
        let apiResponse = buildEntity(hasPages: true)

        // When
        let shouldShowPages = DashboardCard.pages.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShowPages)
    }

    func testShowingPagesCardWithZeroPages() {
        // Given
        let apiResponse = buildEntity(hasPages: false)

        // When
        let shouldShowPages = DashboardCard.pages.shouldShow(for: blog, apiResponse: apiResponse)

        // Then
        XCTAssertTrue(shouldShowPages)
    }

    // MARK: Activity Log

    // TODO: Add test for showing the card if there's activity
    // TODO: Add test for not showing the card if there's no activity

    // MARK: Remote Cards

    func testNotShowingRemoteCardsIfResponseNotPresent() {
        // When
        let shouldShowDrafts = DashboardCard.draftPosts.shouldShow(for: blog, apiResponse: nil)
        let shouldShowScheduled = DashboardCard.scheduledPosts.shouldShow(for: blog, apiResponse: nil)
        let shouldShowStats = DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: nil)
        let shouldShowPages = DashboardCard.pages.shouldShow(for: blog, apiResponse: nil)
        let shouldShowActivityLog = DashboardCard.activityLog.shouldShow(for: blog, apiResponse: nil)

        // Then
        XCTAssertFalse(shouldShowDrafts)
        XCTAssertFalse(shouldShowScheduled)
        XCTAssertFalse(shouldShowStats)
        XCTAssertFalse(shouldShowPages)
        XCTAssertFalse(shouldShowActivityLog)
    }

    func testRemoteCardsIdentifiers() {
        // When
        let identifiers = DashboardCard.RemoteDashboardCard.allCases.map { $0.rawValue }

        // Then
        XCTAssertEqual(identifiers, ["todays_stats", "posts", "pages", "activity", "dynamic"])
    }

    // MARK: Helpers

    private func buildEntity(hasStats: Bool = false,
                             hasDrafts: Bool = false,
                             hasScheduled: Bool = false,
                             hasPublished: Bool = false,
                             hasPages: Bool = false,
                             hasActivity: Bool = false) -> BlogDashboardRemoteEntity {
        let stats = hasStats ? FailableDecodable(value: BlogDashboardRemoteEntity.BlogDashboardStats(views: 1, visitors: 2, likes: 3, comments: 0)) : nil
        let drafts = hasDrafts ? [BlogDashboardRemoteEntity.BlogDashboardPost()] : []
        let scheduled = hasScheduled ? [BlogDashboardRemoteEntity.BlogDashboardPost()] : []
        let posts = BlogDashboardRemoteEntity.BlogDashboardPosts(hasPublished: hasPublished, draft: drafts, scheduled: scheduled)
        let wrappedPosts = FailableDecodable(value: posts)
        let pages = hasPages ? [BlogDashboardRemoteEntity.BlogDashboardPage()] : []
        let wrappedPages = FailableDecodable(value: pages)
        let activities = try? [Activity.mock()]
        let currentActivity = BlogDashboardRemoteEntity.BlogDashboardActivity.CurrentActivity(orderedItems: activities)
        let activity = hasActivity ? FailableDecodable(value: BlogDashboardRemoteEntity.BlogDashboardActivity(current: currentActivity)) : nil
        return BlogDashboardRemoteEntity(posts: wrappedPosts, todaysStats: stats, pages: wrappedPages, activity: activity)
    }

}
