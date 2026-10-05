import XCTest

/// Covers the screens reachable from the site menu, which My Site's "More" row opens.
///
/// These tests only read, so they share one sign-in.
final class SiteMenuTests: JetpackUITestCase {
    override class var resetsAppBeforeEachTest: Bool { false }

    private func siteMenu() throws -> SiteMenuScreen {
        try MySiteScreen(app: app)
            .goToSiteMenu()
    }

    // MARK: - Content

    func testPosts() throws {
        let posts = try siteMenu()
            .goToPosts()
            .waitForScreen()

        for filter in PostsScreen.Filter.allCases.reversed() {
            try posts.select(filter)
        }
    }

    func testPages() throws {
        let pages = try siteMenu()
            .goToPages()
            .waitForScreen()

        for filter in PagesScreen.Filter.allCases.reversed() {
            try pages.select(filter)
        }
    }

    func testMedia() throws {
        try siteMenu()
            .goToMedia()
            .waitForScreen()
    }

    func testComments() throws {
        let comments = try siteMenu()
            .goToComments()
            .waitForScreen()

        for filter in CommentsScreen.Filter.allCases.reversed() {
            try comments.select(filter)
        }
    }

    // MARK: - Traffic

    func testStats() throws {
        let stats = try siteMenu()
            .goToStats()
            .waitForScreen()

        for tab in StatsScreen.Tab.allCases.reversed() {
            try stats.select(tab)
        }
    }

    func testSubscribers() throws {
        try siteMenu()
            .goToSubscribers()
            .waitForScreen()
    }

    func testSocial() throws {
        try siteMenu()
            .goToSocial()
            .waitForScreen()
    }

    func testBlazeCampaigns() throws {
        try siteMenu()
            .goToBlazeCampaigns()
            .waitForScreen()
    }

    // MARK: - Maintenance

    func testActivityLog() throws {
        try siteMenu()
            .goToActivityLog()
            .waitForScreen()
    }

    func testUsers() throws {
        try siteMenu()
            .goToUsers()
            .waitForScreen()
    }

    func testThemes() throws {
        try siteMenu()
            .goToThemes()
            .waitForScreen()
    }

    func testMenus() throws {
        try siteMenu()
            .goToMenus()
            .waitForScreen()
    }

    func testDomains() throws {
        try siteMenu()
            .goToDomains()
            .waitForScreen()
    }

    func testSiteSettings() throws {
        try siteMenu()
            .goToSiteSettings()
            .waitForScreen()
    }
}
