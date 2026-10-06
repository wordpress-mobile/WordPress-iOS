import XCTest

/// Covers the Stats buttons that change what the Traffic tab shows: the chart's metric, type and
/// granularity, a top list's data type, the date range, and the cards themselves.
///
/// The app stores these choices on the device, not on the site, so each test starts from a reset
/// app instead of sharing a sign-in.
final class StatsCustomizationTests: JetpackUITestCase {
    private func stats() throws -> StatsScreen {
        try MySiteScreen(app: app)
            .goToStats()
    }

    func testChartCard() throws {
        let stats = try stats()

        for metric in StatsScreen.Metric.allCases {
            try stats.select(metric)
        }

        // Chart type
        try stats.openChartCardMenu().select("Lines")
        var menu = try stats.openChartCardMenu()
        try stats.wait(until: "the Lines chart type selected") { menu.item("Lines").isSelected }
        try menu.select("Bars")

        // Granularity: the item that opens the submenu is titled with the current one.
        try stats.openChartCardMenu().select("Days").select("Weeks")
        menu = try stats.openChartCardMenu()
        try menu.waitForItems(["Weeks"])
    }

    func testTopListCard() throws {
        let stats = try stats()

        var current = StatsScreen.DataType.postsAndPages
        for dataType in StatsScreen.DataType.allCases {
            try stats.switchCard(listing: current, to: dataType)
            try stats.wait(until: "the first top list card listing \(dataType.title)") {
                stats.firstTopListCardTitle.label == "\(dataType.title) card"
            }
            current = dataType
        }

        for level in StatsScreen.LocationLevel.allCases {
            try stats.select(level)
        }
    }

    func testDateRange() throws {
        let stats = try stats()

        // Presets: these three title the date range button.
        for preset in ["Last 30 Days", "Last 12 Months", "Last 7 Days"] {
            try stats.openDateRangeMenu().select(preset)
            try stats.wait(until: "the date range \(preset)") { stats.dateRangeButton.label.hasPrefix(preset) }
        }

        // Presets: the rest title it with their dates.
        for preset in ["Today", "This Week", "This Month", "This Year", "Last 7 Days"] {
            try stats.openDateRangeMenu().select(preset)
            try stats.waitFor(stats.chartCard)
        }

        // Navigation
        let range = stats.dateRangeButton.label
        stats.dateBackwardButton.tap()
        try stats.wait(until: "an earlier date range") { stats.dateRangeButton.label != range }
        let earlierRange = stats.dateRangeButton.label
        stats.dateForwardButton.tap()
        try stats.wait(until: "a later date range") { stats.dateRangeButton.label != earlierRange }

        // Comparison period
        try stats.openDateRangeMenu().select(beginningWith: "Compare With…").select("No Comparison")
        // The item is titled with the comparison period unless there isn't one.
        try stats.openDateRangeMenu().waitForItems(["Compare With…"])
    }

    func testTodayCard() throws {
        let stats = try stats()

        let range = stats.dateRangeButton.label
        try stats.tapTodayCard()
        try stats.wait(until: "the date range narrowed to today") { stats.dateRangeButton.label != range }
    }

    // A card only lists items that have stats in the date range, and a quiet site can go a week
    // without a view or a referrer, so these two widen the range before opening an item.

    func testPostStats() throws {
        let stats = try stats()

        try stats.openDateRangeMenu().select("Last 12 Months")
        try stats
            .goToFirstItem(ofCardListing: .postsAndPages, titled: "Post Stats")
            .waitForScreen()
    }

    func testReferrerStats() throws {
        let stats = try stats()

        try stats.openDateRangeMenu().select("Last 12 Months")
        try stats
            .goToFirstItem(ofCardListing: .referrers, titled: "Referrer")
            .waitForScreen()
    }

    func testCardLayout() throws {
        let stats = try stats()

        // Move
        try stats.waitFor(stats.todayCard)
        try stats.openChartCardMenu().select("Move Card").select("Move to Top")
        try stats.wait(until: "the chart card above the Today card") {
            stats.chartCard.frame.minY < stats.todayCard.frame.minY
        }

        // Delete
        try stats.openTodayCardMenu().select("Delete Card")
        try stats.wait(until: "the Today card removed") { !stats.todayCard.exists }

        // Add
        try stats.openAddCardMenu().select(beginningWith: "Today,")
        try stats.wait(until: "the Today card added back") { stats.todayCard.exists }
    }
}
