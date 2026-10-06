import XCTest

/// Covers the detail screen each site menu list opens for one of its items.
///
/// These tests only read, so they share one sign-in. The ones that open the editor close it
/// without making a change.
final class SiteMenuDetailTests: JetpackUITestCase {
    override class var resetsAppBeforeEachTest: Bool { false }

    private func siteMenu() throws -> SiteMenuScreen {
        try MySiteScreen(app: app)
            .goToSiteMenu()
    }

    func testPost() throws {
        let editor = try siteMenu()
            .goToPosts()
            .select(.published)
            .goToFirstPost()
            .waitForScreen()

        editor.close()
        try PostsScreen(app: app).waitForScreen()
    }

    func testPage() throws {
        let editor = try siteMenu()
            .goToPages()
            .select(.published)
            .goToFirstPage()
            .waitForScreen()

        editor.close()
        try PagesScreen(app: app).waitForScreen()
    }

    func testComment() throws {
        try siteMenu()
            .goToComments()
            .select(.all)
            .goToFirstComment()
            .waitForScreen()
    }

    func testSubscriber() throws {
        try siteMenu()
            .goToSubscribers()
            .goToFirstSubscriber()
            .waitForScreen()
    }

    func testSocialConnection() throws {
        try siteMenu()
            .goToSocial()
            .goToFirstConnection()
            .waitForScreen()
    }

    func testActivity() throws {
        try siteMenu()
            .goToActivityLog()
            .goToFirstActivity()
            .waitForScreen()
    }

    func testUser() throws {
        try siteMenu()
            .goToUsers()
            .goToFirstUser()
            .waitForScreen()
    }

    func testDomain() throws {
        try siteMenu()
            .goToDomains()
            .goToFirstDomain()
            .waitForScreen()
            .dismiss()
    }
}
