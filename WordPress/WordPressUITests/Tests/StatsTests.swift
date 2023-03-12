import UITestsFoundation
import XCTest

class StatsTests: XCTestCase {
    private var statsScreen: StatsScreen!

    override func setUpWithError() throws {
        setUpTestSuite()
        _ = try LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        statsScreen = try MySiteScreen()
            .goToMenu()
            .goToStatsScreen()
            .switchTo(mode: .insights)
            .refreshStatsIfNeeded()
            .dismissCustomizeInsightsNotice()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        removeApp()
    }

    let insightsStats: [String] = [
        "Your views in the last 7-days are -9 (-82%) lower than the previous 7-days. ",
        "Thursday",
        "34% of views",
        "Best Hour",
        "4 AM",
        "25% of views"
    ]

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

    let yearsChartBars: [String] = [
        "Views,  2019: 9148",
        "Visitors,  2019: 4216",
        "Views,  2018: 1215",
        "Visitors,  2018: 632",
        "Views,  2017: 788",
        "Visitors,  2017: 465"
    ]

    func testInsightsStatsLoadProperly() {
        statsScreen
            .switchTo(mode: .insights)
            .assertStatsAreLoaded(insightsStats)
    }

    func testYearsStatsLoadProperly() {
        statsScreen
            .switchTo(mode: .years)
            .assertStatsAreLoaded(yearsStats)
            .assertChartIsLoaded(yearsChartBars)
    }
}
