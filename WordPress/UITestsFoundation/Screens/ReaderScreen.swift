import ScreenObject
import XCTest

public class ReaderScreen: ScreenObject {

    private let discoverButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Discover"]
    }

    var discoverButton: XCUIElement { discoverButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:skip:next opening_brace
                { $0.tables["Reader"] },
                discoverButtonGetter
            ],
            app: app,
            waitTimeout: 7
        )
    }

    public func openLastPost() -> ReaderScreen {
        getLastPost().tap()
        return self
    }

    public func openLastPostInSafari() -> ReaderScreen {
        getLastPost().buttons["More"].tap()
        app.buttons["Visit"].tap()
        return self
    }

    public func openLastPostComments() throws -> CommentsScreen {
        let commentButton = getLastPost().buttons["0 comment"]
        guard commentButton.waitForIsHittable() else { fatalError("ReaderScreen.Post: Comments button not loaded") }
        commentButton.tap()
        return try CommentsScreen()
    }

    public func getLastPost() -> XCUIElement {
        guard let post = app.cells.lastMatch else { fatalError("ReaderScreen: No posts loaded") }
        scrollDownUntilElementIsFullyVisible(element: post)
        return post
    }

    private func scrollDownUntilElementIsFullyVisible(element: XCUIElement) {
        var loopCount = 0
        // Using isFullyVisibleOnScreen instead of waitForIsHittable to solve a problem on iPad where the desired post
        // was already hittable but the comments button was still not visible.
        while !element.isFullyVisibleOnScreen() && loopCount < 10 {
            loopCount += 1
            app.swipeUp(velocity: .fast)
        }
    }

    private func postContentEquals(_ expected: String) -> Bool {
        let equalsPostContent = NSPredicate(format: "label == %@", expected)
        let isPostContentEqual = app.staticTexts.element(matching: equalsPostContent).waitForIsHittable(timeout: 3)

        return isPostContentEqual
    }

    public func verifyPostContentEquals(_ expected: String) {
        XCTAssertTrue(postContentEquals(expected))
    }

    public func dismissPost() {
        let backButton = app.buttons["Back"]
        let dismissButton = app.buttons["Dismiss"]

        if dismissButton.isHittable { dismissButton.tap() }
        if backButton.isHittable { backButton.tap() }
    }

    public static func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func openDiscover() -> ReaderScreen {
        discoverButton.tap()

        return self
    }
}
