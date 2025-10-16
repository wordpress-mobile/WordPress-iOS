import UITestsFoundation
import XCTest

class StatsTests: XCTestCase {

    let app = XCUIApplication()

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite(
            arguments: ["-ff-override-New Stats", "false"],
            selectWPComSite: WPUITestCredentials.testWPcomPaidSite
        )

        try MySiteScreen()
            .goToMoreMenu()
            .goToStatsScreen()
            .switchTo(mode: "insights")
            .refreshStatsIfNeeded()
            .dismissCustomizeInsightsNotice()
    }

    /// - note: Each of these test can be run independently if needed.
    func testStats() throws {
        try _testInsights()
        try _testTrafficYears()
    }

    func _testInsights() throws {
        try StatsScreen()
            .switchTo(mode: "insights")

        let insightsStats: [String] = [
            "Your views in the last 7-days are -9 (-82%) lower than the previous 7-days. ",
            "Thursday",
            "34% of views",
            "Best Hour",
            "4 AM",
            "25% of views"
        ]

        // The data is shown asyncronously, so we have to wait
        XCTAssertTrue(app.staticTexts[insightsStats[0]].waitForExistence(timeout: 3))

        for stat in insightsStats {
            XCTAssertTrue(app.staticTexts[stat].exists, "Element not found: \(stat)")
        }
    }

    func _testTrafficYears() throws {
        try StatsScreen()
            .switchTo(mode: "traffic")
            .selectByYearPeriod()

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

        // The data is shown asyncronously, so we have to wait
        XCTAssertTrue(app.staticTexts[yearsStats[0]].waitForExistence(timeout: 3))

        for stat in yearsStats {
            XCTAssertTrue(app.staticTexts[stat].exists, "Element not found: \(stat)")
        }

        let currentYear = Calendar.current.component(.year, from: Date())

        let yearsChartBars: [String] = [
            "Views,  \(currentYear): 9,148",
            "Visitors,  \(currentYear): 4,216",
            "Views,  \(currentYear - 1): 1,215",
            "Visitors,  \(currentYear - 1): 632",
            "Views,  \(currentYear - 2): 788",
            "Visitors,  \(currentYear - 2): 465"
        ]

        for stat in yearsChartBars {
            XCTAssertTrue(app.otherElements[stat].exists, "Element not found: \(stat)")
        }

        try StatsScreen()
            .selectVisitorsTab()
    }
}
