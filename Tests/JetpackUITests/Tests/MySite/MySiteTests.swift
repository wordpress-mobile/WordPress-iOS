import XCTest

/// Covers the screens reachable from My Site's header and quick actions.
///
/// These tests only read, so they share one sign-in.
final class MySiteTests: JetpackUITestCase {
    override class var resetsAppBeforeEachTest: Bool { false }

    func testSitePicker() throws {
        try MySiteScreen(app: app)
            .goToSitePicker()
            .waitForScreen()
            .close()
    }

    func testStatsQuickAction() throws {
        try MySiteScreen(app: app)
            .goToStats()
            .waitForScreen()
    }

    func testPostsQuickAction() throws {
        try MySiteScreen(app: app)
            .goToPosts()
            .waitForScreen()
    }

    func testPagesQuickAction() throws {
        try MySiteScreen(app: app)
            .goToPages()
            .waitForScreen()
    }

    func testMediaQuickAction() throws {
        try MySiteScreen(app: app)
            .goToMedia()
            .waitForScreen()
    }
}
