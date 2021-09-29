import XCTest

public class ActionSheetComponent: BaseScreen {
    let blogPostButton: XCUIElement
    let sitePageButton: XCUIElement

    struct ElementIDs {
        static let blogPostButton = "blogPostButton"
        static let sitePageButton = "sitePageButton"
    }

    public init() {
        blogPostButton = XCUIApplication().buttons[ElementIDs.blogPostButton]
        sitePageButton = XCUIApplication().buttons[ElementIDs.sitePageButton]

        super.init(element: blogPostButton)
    }

    public func goToBlogPost() {
        XCTAssert(blogPostButton.waitForExistence(timeout: 3))
        XCTAssert(blogPostButton.waitForIsHittable(timeout: 3))

        XCTAssert(blogPostButton.isHittable)
        blogPostButton.tap()
    }
}
