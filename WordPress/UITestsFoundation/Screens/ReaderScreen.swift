import ScreenObject
import XCTest

public class ReaderScreen: ScreenObject {

    private let discoverButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Discover"]
    }

    var discoverButton: XCUIElement { discoverButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:skip:next opening_brace
                { $0.tables["Reader"] },
                discoverButtonGetter
            ],
            app: app
        )
    }

    public func openTheLastPostInApp() {
        getTheLastPost().tap()
    }

    public func openTheLastPostInSafari() {
        getTheLastPost().buttons["More"].tap()
        app.buttons["Visit"].tap()
    }

    public func getTheLastPost() -> XCUIElement {
        let postPosition = app.cells.count - 1
        let post = app.cells.element(boundBy: postPosition)

        scrollDownUntilElementIsHittable(element: post)
        return post
    }

    private func scrollDownUntilElementIsHittable(element: XCUIElement) {
        var loopCount = 0
        while !element.waitForIsHittable(timeout: 3) && loopCount < 10 {
            loopCount += 1
            app.swipeUp(velocity: .fast)
            print(loopCount)
        }
    }

    public func postContentEquals(expected: String) -> Bool {
        let equalsPostContent = NSPredicate(format: "label == %@", expected)
        let isPostContentEqual = app.staticTexts.element(matching: equalsPostContent).waitForIsHittable(timeout: 3)

        return isPostContentEqual
    }

    public func dismissPost() {
        let backButton = app.buttons["Back"]
        let dismissButton = app.buttons["Dismiss"]

        if dismissButton.isHittable {
            dismissButton.tap()
        } else if backButton.isHittable {
            backButton.tap()
        }
    }

    public static func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func openDiscover() -> ReaderScreen {
        discoverButton.tap()

        return self
    }
}
