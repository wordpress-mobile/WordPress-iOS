import ScreenObject
import XCTest
import XCUITestHelpers

public class ActionSheetComponent: ScreenObject {

    private let blogPostButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["blogPostButton"]
    }

    private let sitePageButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["sitePageButton"]
    }

    var blogPostButton: XCUIElement { blogPostButtonGetter(app) }
    var sitePageButton: XCUIElement { sitePageButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [blogPostButtonGetter, sitePageButtonGetter],
            app: app
        )
    }

    public func goToBlogPost() {
        XCTAssert(blogPostButton.waitForIsHittable(timeout: 3))
        blogPostButton.tap()
    }

    public func goToSitePage() throws -> BlockEditorScreen {
        XCTAssert(sitePageButton.waitForIsHittable(timeout: 3))
        sitePageButton.tap()

        return try BlockEditorScreen()
    }
}
