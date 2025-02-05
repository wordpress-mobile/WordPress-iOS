import ScreenObject
import XCTest

public final class CommentComposerScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.textViews["edit_comment_text_view"].firstMatch
        }
    }

    public func sendComment(_ content: String) {
        let textView = app.textViews["edit_comment_text_view"].firstMatch

        XCTAssertTrue(textView.waitForIsHittable())
        textView.tap()
        textView.typeText(content)

        app.buttons["button_send_comment"].firstMatch.tap()
    }
}
