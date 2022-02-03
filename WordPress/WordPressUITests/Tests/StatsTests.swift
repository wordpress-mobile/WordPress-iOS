import UITestsFoundation
import XCTest

class StatsTests: XCTestCase {
    private var statsScreen: StatsScreen!

    override func setUpWithError() throws {
        setUpTestSuite()
        _ = try LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        statsScreen = try MySiteScreen()
            .goToStatsScreen()
            .switchTo(mode: .insights)
            .dismissCustomizeInsightsNotice()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    let insightsStats: [String] = [
        "35",
        "Views",
        "2,243",
        "Posts",
        "2",
        "Visitors",
        "1,201",
        "Best views ever",
        "48"
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
