import UITestsFoundation
import XCTest

class StatsTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)

        try MySiteScreen()
            .goToMoreMenu()
            .goToStatsScreen()
            .switchTo(mode: "insights")
            .refreshStatsIfNeeded()
            .dismissCustomizeInsightsNotice()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    func testInsightsStatsLoadProperly() throws {
        let insightsStats: [String] = [
            "Your views in the last 7-days are -9 (-82%) lower than the previous 7-days. ",
            "Thursday",
            "34% of views",
            "Best Hour",
            "4 AM",
            "25% of views"
        ]

        try StatsScreen()
            .switchTo(mode: "insights")
            .assertStatsAreLoaded(insightsStats)
    }

    func testTrafficYearsStatsLoadProperly() throws {
        let yearsStats: [String] = [
            "Views 9,148",
            "Visitors 4,216",
            "Likes 1,351",
            "Comments 0",
            "United States, 60",
            "Canada, 44",
            "Germany, 15",
            "France, 14",
            "United Kingdom, 12",
            "India, 121"
        ]

        try StatsScreen()
            .switchTo(mode: "traffic")
            .selectByYearPeriod()
            .assertStatsAreLoaded(yearsStats)
            .selectVisitorsTab()
    }
}
