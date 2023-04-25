import XCTest
@testable import WordPress

class MockDefaultSectionProvider: DefaultSectionProvider {
    var defaultSection: MySiteViewController.Section

    init(defaultSection: MySiteViewController.Section) {
        self.defaultSection = defaultSection
    }
}

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
        let mySiteSettings = MockDefaultSectionProvider(defaultSection: .dashboard)
        QuickStartTourGuide.shared.setup(for: blog, type: .newSite)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog, mySiteSettings: mySiteSettings)

        // Then
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowQuickStartIfDefaultSectionIsSiteMenu() {
        // Given
        let mySiteSettings = MockDefaultSectionProvider(defaultSection: .siteMenu)
        QuickStartTourGuide.shared.setup(for: blog, type: .newSite)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog, mySiteSettings: mySiteSettings)

        // Then
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowQuickStartIfDisabled() {
        // Given
        let mySiteSettings = MockDefaultSectionProvider(defaultSection: .dashboard)
        QuickStartTourGuide.shared.setup(for: blog, type: .newSite)
        QuickStartTourGuide.shared.remove(from: blog)

        // When
        let shouldShow = DashboardCard.quickStart.shouldShow(for: blog, mySiteSettings: mySiteSettings)

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
        let shouldShowNextPost = DashboardCard.nextPost.shouldShow(for: blog, apiResponse: nil)
        let shouldShowCreatePost = DashboardCard.createPost.shouldShow(for: blog, apiResponse: nil)
        let shouldShowStats = DashboardCard.createPost.shouldShow(for: blog, apiResponse: nil)
        let shouldShowPages = DashboardCard.pages.shouldShow(for: blog, apiResponse: nil)
        let shouldShowActivityLog = DashboardCard.activityLog.shouldShow(for: blog, apiResponse: nil)

        // Then
        XCTAssertFalse(shouldShowDrafts)
        XCTAssertFalse(shouldShowScheduled)
        XCTAssertFalse(shouldShowNextPost)
        XCTAssertFalse(shouldShowCreatePost)
        XCTAssertFalse(shouldShowStats)
        XCTAssertFalse(shouldShowPages)
        XCTAssertFalse(shouldShowActivityLog)
    }

    func testRemoteCardsIdentifiers() {
        // When
        let identifiers = DashboardCard.RemoteDashboardCard.allCases.map { $0.rawValue }

        // Then
        XCTAssertEqual(identifiers, ["todays_stats", "posts", "pages", "activity"])
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
