import ScreenObject
import XCTest

public class NotificationsScreen: ScreenObject {
    var notificationsTable: XCUIElement { app.tables["notifications-table"].firstMatch }
    var notificationsDetailsTable: XCUIElement { app.tables["notifications-details-table"].firstMatch }

    var replyCommentButton: XCUIElement { app.buttons["reply-comment-button"].firstMatch }
    var likeCommentButton: XCUIElement { app.buttons["like-comment-button"].firstMatch }

    var replyIndicatorCell: XCUIElement { app.cells["reply-indicator-cell"].firstMatch }
    var replyIndicatorText: XCUIElement { app.staticTexts["reply-indicator-text"].firstMatch }
    var trashCommentButton: XCUIElement { app.cells["trash-comment-button"].firstMatch }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.tables["notifications-table"].firstMatch
        }
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
            XCTAssertTrue(replyCommentButton.exists)
            XCTAssertTrue(likeCommentButton.exists)
            XCTAssertTrue(trashCommentButton.exists)
        default:
            XCTAssertTrue(notificationsDetailsTable.exists)
        }

        // If on iPhone, tap back to return to notifications list
        if XCTestCase.isPhone {
            navigateBack()
        }

        return self
    }

    public func replyToComment(withText text: String) throws -> Self {
        replyCommentButton.tap()
        try CommentComposerScreen()
            .sendComment(text)
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

    public func getNumberOfLikesForNotification() throws -> (NotificationsScreen, Int) {
        guard likeCommentButton.waitForExistence(timeout: 5) else {
            throw UIElementNotFoundError(message: "likeCommentButton not found")
        }
        let totalLikesInString = likeCommentButton.label.prefix(1)
        let totalLikes = Int(totalLikesInString) ?? 0
        return (self, totalLikes)
    }

    public func likeComment() -> Self {
        let isCommentOnTextDisplayed = app.staticTexts["Comment on"].firstMatch.waitForExistence(timeout: 5)

        if isCommentOnTextDisplayed {
            app.buttons["like-comment-button"].firstMatch.tap()
        }
        return self
    }

    @discardableResult
    public func verifyCommentLiked(expectedLikes: Int, file: StaticString = #file, line: UInt = #line) throws -> Self {
        var tries = 0

        while !likeCommentButton.label.hasSuffix(.commentLikedLabel) && tries < 5 {
            sleep(1) // Wait for 1 second
            tries += 1
        }

        XCTAssertTrue(likeCommentButton.label.hasSuffix(.commentLikedLabel))

        let (_, currentLikes) = try getNumberOfLikesForNotification()
        XCTAssertEqual(currentLikes, expectedLikes, file: file, line: line)

        return self
    }

    public static func isLoaded() -> Bool {
        (try? NotificationsScreen().isLoaded) ?? false
    }
}

private extension String {
    static let commentLikedLabel = "Comment is liked"
    static let commentNotLikedLabel = "Comment is not liked"
}
