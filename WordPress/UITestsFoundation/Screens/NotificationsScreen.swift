import ScreenObject
import XCTest

public class NotificationsScreen: ScreenObject {

    private let replyCommentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["reply-comment-button"]
    }

    private let likeCommentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["like-comment-button"]
    }

    private let trashCommentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["trash-comment-button"]
    }

    private let notificationsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["notifications-table"]
    }

    private let notificationsDetailsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["notifications-details-table"]
    }

    private let replyTextViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["reply-text-view"]
    }

    private let replyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["reply-button"]
    }

    private let replyIndicatorTextGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["reply-indicator-text"]
    }

    private let replyIndicatorCellGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["reply-indicator-cell"]
    }

    var likeCommentButton: XCUIElement { likeCommentButtonGetter(app) }
    var notificationsDetailsTable: XCUIElement { notificationsDetailsTableGetter(app) }
    var notificationsTable: XCUIElement { notificationsTableGetter(app) }
    var replyButton: XCUIElement { replyButtonGetter(app) }
    var replyCommentButton: XCUIElement { replyCommentButtonGetter(app) }
    var replyIndicatorCell: XCUIElement { replyIndicatorCellGetter(app) }
    var replyIndicatorText: XCUIElement { replyIndicatorTextGetter(app) }
    var replyTextView: XCUIElement { replyTextViewGetter(app) }
    var trashCommentButton: XCUIElement { trashCommentButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ notificationsTableGetter ],
            app: app
        )
    }

    @discardableResult
    public func openNotification(withSubstring substring: String) -> NotificationsScreen {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", substring)).element.tap()
        return self
    }

    @discardableResult
    public func verifyNotification(ofType type: String, file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(app.navigationBars.containing(NSPredicate(format: "label CONTAINS[c] %@", type)).firstMatch.waitForExistence(timeout: 5), file: file, line: line)

        switch type {
        case "Comment":
            XCTAssertTrue(replyCommentButton.waitForExistence(timeout: 5), file: file, line: line)
            XCTAssertTrue(likeCommentButton.waitForExistence(timeout: 5), file: file, line: line)
            XCTAssertTrue(trashCommentButton.waitForExistence(timeout: 5), file: file, line: line)
        default:
            XCTAssertTrue(notificationsDetailsTable.waitForExistence(timeout: 5), file: file, line: line)
        }

        // If on iPhone, tap back to return to notifications list
        if XCUIDevice.isPhone {
            navigateBack()
        }

        return self
    }

    public func replyToComment(withText text: String) -> Self {
        waitAndTap(replyCommentButton)
        replyTextView.typeText(text)
        replyButton.tap()

        return self
    }

    @discardableResult
    public func verifyReplySent(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(replyIndicatorCell.waitForExistence(timeout: 5), file: file, line: line)

        let expectedReplyIndicatorLabel = NSLocalizedString("You replied to this comment.", comment: "Text to look for")
        let actualReplyIndicatorLabel = replyIndicatorText.label.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(actualReplyIndicatorLabel, expectedReplyIndicatorLabel, file: file, line: line)

        return self
    }

    public static func isLoaded() -> Bool {
        (try? NotificationsScreen().isLoaded) ?? false
    }
}
