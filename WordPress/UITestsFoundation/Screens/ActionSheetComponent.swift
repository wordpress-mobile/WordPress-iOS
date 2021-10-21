import ScreenObject
import XCTest
import XCUITestHelpers

public class ActionSheetComponent: ScreenObject {

    private static let getBlogPostButton: (XCUIApplication) -> XCUIElement = {
        $0.buttons["blogPostButton"]
    }

    private static let getSitePageButton: (XCUIApplication) -> XCUIElement = {
        $0.buttons["sitePageButton"]
    }

    var blogPostButton: XCUIElement { Self.getBlogPostButton(app) }
    var sitePageButton: XCUIElement { Self.getSitePageButton(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [Self.getBlogPostButton, Self.getSitePageButton])
    }

    public func goToBlogPost() {
        XCTAssert(blogPostButton.waitForExistence(timeout: 3))
        XCTAssert(blogPostButton.waitForIsHittable(timeout: 3))

        XCTAssert(blogPostButton.isHittable)
        blogPostButton.tap()
    }
}
