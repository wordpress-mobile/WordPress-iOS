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

    func testYearsStatsLoadProperly() throws {
        let yearsStats: [String] = [
            "9,148",
            "+7,933 (653%)",
            "United States, 60",
            "Canada, 44",
            "Germany, 15",
            "France, 14",
            "United Kingdom, 12",
            "India, 121"
        ]

        let currentYear = Calendar.current.component(.year, from: Date())
        let yearsChartBars: [String] = [
            "Views,  \(currentYear): 9148",
            "Visitors,  \(currentYear): 4216",
            "Views,  \(currentYear - 1): 1215",
            "Visitors,  \(currentYear - 1): 632",
            "Views,  \(currentYear - 2): 788",
            "Visitors,  \(currentYear - 2): 465"
        ]

        try StatsScreen()
            .switchTo(mode: "years")
            .assertStatsAreLoaded(yearsStats)
            .assertChartIsLoaded(yearsChartBars)
    }
}
