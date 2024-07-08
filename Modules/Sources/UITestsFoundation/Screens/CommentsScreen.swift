import ScreenObject
import XCTest

public class CommentsScreen: ScreenObject {

    private let navigationBarTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Comments"]
    }

    private let replyFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["reply-to-post-text-field"]
    }

    private let replyMessageNoticeGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["notice_title_and_message"]
    }

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["Reader"]
    }

    private let replyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Reply"]
    }

    var backButton: XCUIElement { backButtonGetter(app) }
    var replyButton: XCUIElement { replyButtonGetter(app) }
    var replyField: XCUIElement { replyFieldGetter(app) }
    var replyMessageNotice: XCUIElement { replyMessageNoticeGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                navigationBarTitleGetter,
                replyFieldGetter
            ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func navigateBack() throws -> ReaderScreen {
        backButton.tap()
        return try ReaderScreen()
    }

    @discardableResult
    public func replyToPost(_ comment: String) -> CommentsScreen {
        replyField.tap()
        replyField.typeText(comment)
        replyButton.tap()
        return self
    }

    public func verifyCommentsListEmpty() -> CommentsScreen {
        XCTAssertTrue(app.tables.firstMatch.label == "Empty list")
        XCTAssertTrue(app.staticTexts["Be the first to leave a comment."].isHittable)
        XCTAssertTrue(app.cells.count == 0)
        return self
    }

    public func verifyCommentSent(_ content: String) {
        XCTAssertTrue(replyMessageNotice.waitForIsHittable(), "'Reply Sent' message was not displayed.")
        XCTAssertTrue(app.cells.containing(.textView, identifier: content).count == 1, "Comment was not visible")
    }
}
