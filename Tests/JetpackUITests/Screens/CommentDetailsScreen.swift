import XCTest

/// The details of one comment.
final class CommentDetailsScreen: ScreenObject {
    private let replyButtonGetter: ElementGetter = {
        $0.buttons["reply-comment-button"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [replyButtonGetter], app: app)
    }
}
