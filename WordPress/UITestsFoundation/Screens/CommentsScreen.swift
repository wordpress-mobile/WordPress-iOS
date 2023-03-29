import ScreenObject
import XCTest

public class CommentsScreen: ScreenObject {

    private let replyTextViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["ReplyText"]
    }

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["Reader"]
    }

    private let replyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Reply"]
    }

    var replyTextView: XCUIElement { replyTextViewGetter(app) }
    var backButton: XCUIElement { backButtonGetter(app) }
    var replyButton: XCUIElement { replyButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:skip:next opening_brace
                { $0.navigationBars["Comments"] },
                replyTextViewGetter
            ],
            app: app,
            waitTimeout: 7
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
    public func replyPost(_ comment: String) -> CommentsScreen {
        app.otherElements.containing(.staticText, identifier: "Reply to post").lastMatch?.tap()
        replyTextView.typeText(comment)
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
        let replySentMessage = app.otherElements["notice_title_and_message"]
        XCTAssertTrue(replySentMessage.waitForIsHittable(), "'Reply Sent' message was not displayed.")
        XCTAssertTrue(app.cells.containing(.textView, identifier: content).count == 1, "Comment was not visible")
    }
}
