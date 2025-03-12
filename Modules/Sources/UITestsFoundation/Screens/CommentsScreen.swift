import ScreenObject
import XCTest

public class CommentsScreen: ScreenObject {

    private let addCommentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["button_add_comment_large"]
    }

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["Reader"]
    }

    private let emptyImageGetter: (XCUIApplication) -> XCUIElement = {
        $0.images["wp-illustration-reader-empty"]
    }

    private let navigationBarTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Comments"]
    }

    private let replyFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["edit_comment_text_view"]
    }

    private let replyMessageNoticeGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["notice_title_and_message"]
    }

    private let sendButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["button_send_comment"]
    }

    var addCommentButton: XCUIElement { addCommentButtonGetter(app) }
    var backButton: XCUIElement { backButtonGetter(app) }
    var emptyImage: XCUIElement { emptyImageGetter(app) }
    var replyField: XCUIElement { replyFieldGetter(app) }
    var replyMessageNotice: XCUIElement { replyMessageNoticeGetter(app) }
    var sendButton: XCUIElement { sendButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                navigationBarTitleGetter,
                addCommentButtonGetter
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
        addCommentButton.tap()
        replyField.typeText(comment)
        sendButton.tap()
        return self
    }

    public func verifyCommentsListEmpty() -> CommentsScreen {
        XCTAssertTrue(emptyImage.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Be the first to leave a comment."].isHittable)
        XCTAssertTrue(app.cells.containing(.button, identifier: "reply-comment-button").count == 0)
        return self
    }

    public func verifyCommentSent(_ content: String) {
        let comment = app.cells.containing(.staticText, identifier: content)
        let commentExists = comment.firstMatch.waitForExistence(timeout: 3)
        let commentIsUnique = comment.count == 1

        XCTAssertTrue(commentExists, "Comment not found.")
        XCTAssertTrue(commentIsUnique, "Multiple comments found.")
    }
}
