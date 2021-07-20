import UITestsFoundation
import XCTest

class ActionSheetComponent: BaseScreen {
    let storyPostbutton: XCUIElement
    let blogPostButton: XCUIElement
    let sitePageButton: XCUIElement

    struct ElementIDs {
        static let storyPostButton = "storyButton"
        static let blogPostButton = "blogPostButton"
        static let sitePageButton = "sitePageButton"
    }

    init() {
        storyPostbutton = XCUIApplication().buttons[ElementIDs.storyPostButton]
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

    func gotoStoryPost() {
        XCTAssert(storyPostbutton.waitForExistence(timeout: 3))
        XCTAssert(storyPostbutton.waitForHittability(timeout: 3))
        XCTAssert(storyPostbutton.isHittable)
        storyPostbutton.tap()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementIDs.blogPostButton].waitForExistence(timeout: 3)
    }
}
