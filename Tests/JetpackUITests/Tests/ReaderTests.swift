import XCTest

/// Covers the Reader tab: its menu, its streams, a post and a post's menu.
///
/// Runs on the fixtures backend. Opening a post in the Reader counts as a view of it and can mark
/// it as seen, so against a real account these tests would leave a trace. The fixture account
/// always has the same subscriptions and posts, which the tests assert on.
final class ReaderTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }
    override class var resetsAppBeforeEachTest: Bool { false }

    private enum Fixture {
        static let post = "Optimizing Meat 2.0"
        static let postSite = "Longreads"
        static let postAuthor = "Aaron Gilbreath"
        static let subscriptions = ["Automattic Design", "WordPress.com News"]
    }

    private func reader() throws -> ReaderScreen {
        try MySiteScreen(app: app)
            .goToReader()
    }

    func testMenuListsTheSubscriptions() throws {
        let reader = try reader()

        for name in Fixture.subscriptions {
            XCTAssertTrue(reader.menu.staticTexts[name].exists, "\(name) isn't in the menu")
        }
    }

    func testMenuEditing() throws {
        try reader()
            .toggleEditing()
            .toggleEditing()
    }

    func testRecent() throws {
        let recent = try reader()
            .goTo(.recent)

        try recent.waitFor(recent.post(titled: Fixture.post))
    }

    func testSaved() throws {
        let saved = try reader()
            .goTo(.saved)

        try saved.wait(until: "an empty Saved stream") { saved.isEmpty }
    }

    func testLikes() throws {
        let likes = try reader()
            .goTo(.likes)

        try likes.wait(until: "an empty Likes stream") { likes.isEmpty }
    }

    func testSearch() throws {
        let search = try reader()
            .goTo(.search)

        try search.waitFor(app.searchFields.firstMatch)
        for scope in ["posts", "sites"] {
            XCTAssertTrue(app.buttons[scope].exists, "The \(scope) scope is missing")
        }
    }

    func testSubscriptions() throws {
        let subscriptions = try reader()
            .goTo(.subscriptions)

        for name in Fixture.subscriptions {
            let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
            try subscriptions.waitFor(row)
        }
    }

    func testSubscribedSite() throws {
        try reader()
            .goToSubscription(named: "WordPress.com News")
            .waitForScreen()
    }

    func testPost() throws {
        let post = try reader()
            .goTo(.recent)
            .goToPost(titled: Fixture.post)
            .waitForScreen()

        XCTAssertTrue(post.site(named: Fixture.postSite).exists, "The post's site isn't shown")
        XCTAssertTrue(post.author(named: Fixture.postAuthor).exists, "The post's author isn't shown")
    }

    func testPostMenu() throws {
        try reader()
            .goTo(.recent)
            .openMenu(ofPostTitled: Fixture.post)
            .waitForItems(["Share", "Copy Link", "View in Browser", "Unsubscribe"])
    }
}
