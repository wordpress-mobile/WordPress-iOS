import XCTest

/// Covers the analytics events the app sends to Tracks.
///
/// Only the fixtures backend can see them: the app's requests to Tracks are answered by a fixture,
/// and the test reads what they carried.
final class AnalyticsTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }
    override class var resetsAppBeforeEachTest: Bool { false }

    func testShowingMySiteIsTracked() throws {
        try MySiteScreen(app: app)
            .waitForScreen()

        try waitForAnalyticsEvent("jpios_my_site_dashboard_shown", properties: ["blog_id": "106707880"])
    }

    func testOpeningStatsFromAQuickActionIsTracked() throws {
        try MySiteScreen(app: app)
            .goToStats()
            .waitForScreen()

        let event = try waitForAnalyticsEvent("jpios_stats_accessed")
        XCTAssertEqual(event.properties["tap_source"], "quick_actions")
        XCTAssertEqual(event.properties["tab_source"], "dashboard")
        XCTAssertEqual(event.properties["blog_id"], "106707880")
    }
}
