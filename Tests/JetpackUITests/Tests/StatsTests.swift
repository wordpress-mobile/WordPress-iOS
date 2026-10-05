import XCTest

/// Covers what every button on the Stats screen opens, on each of its three tabs.
///
/// These tests open menus, sheets and detail screens without choosing anything in them, so they
/// share one sign-in. `StatsCustomizationTests` covers the buttons that change what Stats shows.
final class StatsTests: JetpackUITestCase {
    override class var resetsAppBeforeEachTest: Bool { false }

    private func stats(_ tab: StatsScreen.Tab = .traffic) throws -> StatsScreen {
        try MySiteScreen(app: app)
            .goToStats()
            .select(tab)
    }

    // MARK: - Traffic

    func testNavigationBarMenu() throws {
        try stats()
            .openNavigationBarMenu()
            .waitForItems(["Disable New Stats", "Send Feedback"])
    }

    func testTodayCardMenu() throws {
        try stats()
            .openTodayCardMenu()
            .waitForItems(["Learn More", "Move Card", "Delete Card"])
    }

    func testChartCardMenu() throws {
        try stats()
            .openChartCardMenu()
            .waitForItems(["Lines", "Bars", "Show Data", "Learn More", "Move Card", "Edit Card", "Delete Card"])
    }

    func testChartCardMoveMenu() throws {
        try stats()
            .openChartCardMenu()
            .select("Move Card")
            .waitForItems(["Move Up", "Move to Top", "Move Down", "Move to Bottom"])
    }

    func testChartCardGranularityMenu() throws {
        try stats()
            .openChartCardMenu()
            .select("Days")
            .waitForItems(["Automatic", "Weeks", "Months", "Years"])
    }

    func testChartData() throws {
        try stats()
            .goToChartData()
            .waitForScreen()
            .close()
    }

    func testChartCardCustomization() throws {
        try stats()
            .goToChartCardCustomization()
            .waitForScreen()
            .cancel()
    }

    func testTopListCardMenu() throws {
        try stats()
            .openMenu(ofCardListing: .postsAndPages)
            .waitForItems(["Learn More", "Move Card", "Edit Card", "Delete Card"])
    }

    func testTopListCardCustomization() throws {
        try stats()
            .goToCustomization(ofCardListing: .postsAndPages)
            .waitForScreen()
            .cancel()
    }

    func testTopListCardDataTypeMenu() throws {
        try stats()
            .openDataTypeMenu(ofCardListing: .postsAndPages)
            .waitForItems(StatsScreen.DataType.allCases.map(\.title))
    }

    func testPostsAndPagesShowAll() throws {
        try stats()
            .goToAllItems(ofCardListing: .postsAndPages)
            .waitForScreen()
    }

    func testReferrersShowAll() throws {
        try stats()
            .goToAllItems(ofCardListing: .referrers)
            .waitForScreen()
    }

    func testLocationsShowAll() throws {
        try stats()
            .goToAllItems(ofCardListing: .locations)
            .waitForScreen()
    }

    func testLocationLevelMenu() throws {
        try stats()
            .openLocationLevelMenu()
            .waitForItems(StatsScreen.LocationLevel.allCases.map(\.rawValue))
    }

    func testAddCardMenu() throws {
        try stats()
            .openAddCardMenu()
            .waitForScreen()
    }

    func testTimeZoneInfo() throws {
        try stats()
            .openTimeZoneInfo()
    }

    func testDateRangeMenu() throws {
        let presets = ["Last 7 Days", "Last 30 Days", "Last 12 Months", "Today", "This Week", "This Month", "This Year"]
        try stats()
            .openDateRangeMenu()
            .waitForItems(presets + ["More…"])
    }

    func testComparisonMenu() throws {
        let menu = try stats()
            .openDateRangeMenu()
            .select(beginningWith: "Compare With…")

        try menu.waitForItems(["No Comparison"])
        try menu.waitFor(menu.item(beginningWith: "Preceding Period"))
        try menu.waitFor(menu.item(beginningWith: "Last Year"))
    }

    func testCustomDateRange() throws {
        try stats()
            .goToCustomDateRange()
            .waitForScreen()
            .cancel()
    }

    // MARK: - Insights

    func testInsightsViewsAndVisitors() throws {
        try stats(.insights)
            .goToViewsAndVisitors()
            .waitForScreen()
    }

    func testInsightsChart() throws {
        let stats = try stats(.insights)

        for chart in StatsScreen.InsightsChart.allCases {
            try stats.select(chart)
        }
    }

    func testInsightsTotalLikes() throws {
        try stats(.insights)
            .goToDetails(of: .totalLikes)
            .waitForScreen()
    }

    func testInsightsTotalComments() throws {
        try stats(.insights)
            .goToDetails(of: .totalComments)
            .waitForScreen()
    }

    func testInsightsTotalSubscribers() throws {
        try stats(.insights)
            .goToDetails(of: .totalSubscribers)
            .waitForScreen()
    }

    func testInsightsLatestPost() throws {
        try stats(.insights)
            .goToLatestPost()
            .waitForScreen()
            .dismiss()
    }

    func testInsightsManageCards() throws {
        try stats(.insights)
            .goToManageStatsCards()
            .waitForScreen()
            .close()
    }

    func testInsightsAddCard() throws {
        try stats(.insights)
            .goToManageStatsCardsFromAddCard()
            .waitForScreen()
            .close()
    }

    // MARK: - Subscribers

    func testSubscribersViewMore() throws {
        try stats(.subscribers)
            .goToAllSubscribers()
            .waitForScreen()
    }
}
