import XCTest

/// Checks that the fixtures have everything Stats asks for, so that its screens show data.
///
/// Each test walks part of Stats and then fails if a request went unanswered, or if Stats reported
/// that a card failed to load, which is what happens when a fixture has the wrong shape.
///
/// The walks change what the Traffic tab shows, which the app remembers, so each test starts from
/// a reset app.
final class StatsFixtureTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }

    private func stats() throws -> StatsScreen {
        try MySiteScreen(app: app)
            .goToStats()
    }

    func testTrafficCards() throws {
        let stats = try stats()

        // Cards below the fold only load once they're scrolled to, and the button to add one is
        // below them all.
        try stats.scroll(
            to: stats.addCardButton,
            in: stats.content,
            maxSwipes: StatsScreen.maxSwipes,
            waitsForExistence: false
        )

        try assertStatsLoaded()
    }

    func testEveryTopList() throws {
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

        try assertStatsLoaded()
    }

    func testEveryDateRange() throws {
        let stats = try stats()

        let presets = ["Today", "This Week", "This Month", "This Year", "Last 30 Days", "Last 12 Months", "Last 7 Days"]
        for preset in presets {
            try stats.openDateRangeMenu().select(preset)
            try stats.waitFor(stats.chartCard)
        }

        try assertStatsLoaded()
    }

    func testPostStats() throws {
        _ = try stats()
            .goToFirstItem(ofCardListing: .postsAndPages, titled: "Post Stats")

        try assertStatsLoaded()
    }

    func testInsightsTab() throws {
        let stats = try stats()
            .select(.insights)
        scrollToTheEnd(of: stats)

        try assertStatsLoaded()
    }

    func testSubscribersTab() throws {
        let stats = try stats()
            .select(.subscribers)
        scrollToTheEnd(of: stats)

        try assertStatsLoaded()
    }

    /// Scrolls through a tab, so that it asks for what it only loads once it's on screen.
    private func scrollToTheEnd(of stats: StatsScreen) {
        for _ in 0..<6 {
            stats.swipeUp(stats.content)
        }
    }

    /// Fails if Stats asked for something no fixture answered, or reported an error loading a card.
    private func assertStatsLoaded(file: StaticString = #filePath, line: UInt = #line) throws {
        // Stats reports its errors as analytics events, which the app sends once a second when it
        // runs against the fixtures.
        Thread.sleep(forTimeInterval: 3)

        let unanswered = try unansweredRequests()
            .filter { $0.url.path().contains("/stats") || $0.url.path().contains("/posts/") }
            .map { "No fixture for \($0.method) \($0.url.absoluteString)" }
        let errors = try sentAnalyticsEvents()
            .filter { $0.name == "jpios_jetpack_stats_error_encountered" }
            .map { "Stats reported \($0)" }
        let problems = Set(unanswered + errors).sorted()

        XCTAssertTrue(problems.isEmpty, problems.joined(separator: "\n"), file: file, line: line)
    }
}
