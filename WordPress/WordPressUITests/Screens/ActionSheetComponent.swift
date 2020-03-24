import Foundation
import XCTest

class ActionSheetComponent: BaseScreen {
    let blogPostButton: XCUIElement
    let sitePageButton: XCUIElement

    struct ElementIDs {
        static let blogPostButton = "blogPostButton"
        static let sitePageButton = "sitePageButton"
    }

    init() {
        blogPostButton = XCUIApplication().buttons[ElementIDs.blogPostButton]
        sitePageButton = XCUIApplication().buttons[ElementIDs.sitePageButton]

        super.init(element: blogPostButton)
    }

    func gotoBlogPost() {
        XCTAssert(blogPostButton.waitForExistence(timeout: 3))
        XCTAssert(blogPostButton.waitForHittability(timeout: 3))

        XCTAssert(blogPostButton.isHittable)
        blogPostButton.tap()
    }

    func gotoSitePage() {
        XCTAssert(sitePageButton.waitForExistence(timeout: 3))
        XCTAssert(sitePageButton.waitForHittability(timeout: 3))

        XCTAssert(sitePageButton.isHittable)
        sitePageButton.tap()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementIDs.blogPostButton].waitForExistence(timeout: 3)
    }
}
