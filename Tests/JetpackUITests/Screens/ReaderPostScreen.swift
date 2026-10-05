import XCTest

/// One post, opened in the Reader.
final class ReaderPostScreen: ScreenObject {
    private let saveButtonGetter: ElementGetter = {
        $0.buttons["Save post"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [saveButtonGetter], app: app)
    }

    /// The button naming the post's author, which also carries the date it was published.
    func author(named name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    /// The button naming the site the post is on.
    func site(named name: String) -> XCUIElement {
        app.buttons[name]
    }
}
