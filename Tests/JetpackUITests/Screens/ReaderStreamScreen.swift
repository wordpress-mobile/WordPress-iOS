import XCTest

/// A list of posts in the Reader: one of its streams, or the posts of one site.
final class ReaderStreamScreen: ScreenObject {
    /// - Parameter title: The stream's title, which is the identifier of its navigation bar.
    init(title: String, app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [{ $0.navigationBars[title] }], app: app)
    }

    var table: XCUIElement { app.tables["reader_table_view"] }

    /// Whether the stream has loaded and has no posts.
    ///
    /// The stream's own message ("No saved posts", "Nothing liked yet") isn't in the accessibility
    /// hierarchy, so this goes by the label UIKit gives a table with no rows.
    var isEmpty: Bool { table.label == "Empty list" }

    /// The card for the post titled `title`.
    func post(titled title: String) -> XCUIElement {
        table.cells.containing(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
    }

    func goToPost(titled title: String) throws -> ReaderPostScreen {
        try tap(table.staticTexts[title].firstMatch)
        return try ReaderPostScreen(app: app)
    }

    /// The like button on a post's card. Its label says whether the post is liked, and by how
    /// many: "Like. 34 likes." or "Remove like. 35 likes."
    func likeButton(ofPostTitled title: String) -> XCUIElement {
        post(titled: title).buttons["reader-like-button"]
    }

    /// Likes a post from its card, and waits for the card to show it as liked.
    @discardableResult
    func like(postTitled title: String) throws -> Self {
        let button = likeButton(ofPostTitled: title)
        try tap(button)
        try wait(until: "\(title) shown as liked") { button.label.hasPrefix("Remove like") }
        return self
    }

    func goBackToMenu() throws -> ReaderScreen {
        goBack()
        return try ReaderScreen(app: app)
    }

    func openMenu(ofPostTitled title: String) throws -> MenuComponent {
        let card = post(titled: title)
        try waitFor(card)
        card.buttons["reader-more-button"].tap()
        return try MenuComponent(expecting: "Copy Link", app: app)
    }
}
