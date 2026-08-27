import XCTest
@testable import WordPress
@testable import WordPressData

/// Covers the `.todaysStats` / `.todaysStatsNew` mutual exclusion across the
/// `newStats` flag crossed with context availability, plus the shared
/// personalization/analytics identity.
class DashboardTodayStatsNewCardTests: CoreDataTestCase {

    private let featureFlags = FeatureFlagOverrideStore()

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
    }

    override func tearDown() {
        featureFlags.override(FeatureFlag.newStats, withValue: FeatureFlag.newStats.originalValue)
        super.tearDown()
    }

    // MARK: - Mutual exclusion

    func testFlagOnShowsNewCardAndHidesLegacy() {
        featureFlags.override(FeatureFlag.newStats, withValue: true)
        let blog = makeEligibleBlog()
        let apiResponse = buildStatsEntity()

        XCTAssertTrue(DashboardCard.todaysStatsNew.shouldShow(for: blog, apiResponse: apiResponse))
        XCTAssertFalse(DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: apiResponse))
    }

    func testFlagOffShowsLegacyCardAndHidesNew() {
        featureFlags.override(FeatureFlag.newStats, withValue: false)
        let blog = makeEligibleBlog()
        let apiResponse = buildStatsEntity()

        XCTAssertTrue(DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: apiResponse))
        XCTAssertFalse(DashboardCard.todaysStatsNew.shouldShow(for: blog, apiResponse: apiResponse))
    }

    // MARK: - Fallback when the context is unavailable

    func testFlagOnFallsBackToLegacyWhenNoAuthToken() {
        featureFlags.override(FeatureFlag.newStats, withValue: true)
        // An account with an empty auth token cannot build a StatsContext, so the
        // eligibility predicate must fail and the legacy card must show instead.
        let blog = BlogBuilder(mainContext).withAnAccount(authToken: "").build()
        blog.isAdmin = true
        let apiResponse = buildStatsEntity()

        XCTAssertFalse(DashboardCard.newStatsActive(for: blog))
        XCTAssertFalse(DashboardCard.todaysStatsNew.shouldShow(for: blog, apiResponse: apiResponse))
        XCTAssertTrue(DashboardCard.todaysStats.shouldShow(for: blog, apiResponse: apiResponse))
    }

    func testFlagOnFallsBackToLegacyWithoutDotComID() {
        featureFlags.override(FeatureFlag.newStats, withValue: true)
        let blog = BlogBuilder(mainContext, dotComID: nil).withAnAccount().build()
        blog.isAdmin = true
        let apiResponse = buildStatsEntity()

        XCTAssertFalse(DashboardCard.newStatsActive(for: blog))
        XCTAssertFalse(DashboardCard.todaysStatsNew.shouldShow(for: blog, apiResponse: apiResponse))
    }

    // MARK: - Remote gating still applies

    func testNewCardHiddenWithoutRemoteStats() {
        featureFlags.override(FeatureFlag.newStats, withValue: true)
        let blog = makeEligibleBlog()

        XCTAssertFalse(DashboardCard.todaysStatsNew.shouldShow(for: blog, apiResponse: nil))
        XCTAssertFalse(DashboardCard.todaysStatsNew.shouldShow(for: blog, apiResponse: buildStatsEntity(hasStats: false)))
    }

    // MARK: - Flag transition changes the diffable item identity

    func testFlagTransitionProducesDifferentItemIdentity() {
        let apiResponse = buildStatsEntity()
        let legacyItem = DashboardNormalCardModel(cardType: .todaysStats, dotComID: 1, entity: apiResponse)
        let newItem = DashboardNormalCardModel(cardType: .todaysStatsNew, dotComID: 1, entity: apiResponse)

        // Same site and payload, different rendering: the diffable data source
        // must treat these as different items so the cell swaps on a flag flip.
        XCTAssertNotEqual(legacyItem, newItem)
        XCTAssertNotEqual(DashboardItem.cards(.normal(legacyItem)), DashboardItem.cards(.normal(newItem)))
    }

    // MARK: - Shared personalization + analytics identity

    func testSharesPersonalizationKeyWithLegacyCard() {
        XCTAssertEqual(
            DashboardCard.todaysStatsNew.blogDashboardPersonalizationKey,
            DashboardCard.todaysStats.blogDashboardPersonalizationKey
        )
    }

    func testNewCardIsNotIndependentlyPersonalizable() {
        XCTAssertFalse(DashboardCard.personalizableCards.contains(.todaysStatsNew))
        XCTAssertTrue(DashboardCard.personalizableCards.contains(.todaysStats))
    }

    func testAnalyticsReportLegacyCardIdentity() {
        XCTAssertEqual(
            DashboardCard.todaysStatsNew.analyticProperties["card"] as? String,
            DashboardCard.todaysStats.rawValue
        )
    }

    // MARK: - Helpers

    private func makeEligibleBlog() -> Blog {
        let blog = BlogBuilder(mainContext).withAnAccount().build()
        blog.isAdmin = true
        return blog
    }

    private func buildStatsEntity(hasStats: Bool = true) -> BlogDashboardRemoteEntity {
        let stats = hasStats
            ? FailableDecodable(value: BlogDashboardRemoteEntity.BlogDashboardStats(views: 1, visitors: 2, likes: 3, comments: 0))
            : nil
        return BlogDashboardRemoteEntity(posts: nil, todaysStats: stats, pages: nil, activity: nil)
    }
}
