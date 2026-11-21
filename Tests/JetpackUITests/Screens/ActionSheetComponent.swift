import XCTest

/// The sheet shown by My Site's create button, for choosing what to create.
final class ActionSheetComponent: ScreenObject {
    private let blogPostButtonGetter: ElementGetter = {
        $0.buttons["blogPostButton"]
    }

    private let sitePageButtonGetter: ElementGetter = {
        $0.buttons["sitePageButton"]
    }

    var blogPostButton: XCUIElement { blogPostButtonGetter(app) }
    var sitePageButton: XCUIElement { sitePageButtonGetter(app) }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [blogPostButtonGetter, sitePageButtonGetter], app: app)
    }

    func goToBlogPost() throws -> EditorScreen {
        blogPostButton.tap()
        return try EditorScreen(app: app)
    }
}
