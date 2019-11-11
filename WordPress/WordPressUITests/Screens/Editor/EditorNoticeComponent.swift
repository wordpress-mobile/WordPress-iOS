import Foundation
import XCTest

class EditorNoticeComponent: BaseScreen {
    let noticeAction: XCUIElement

    private let expectedNoticeTitle: String

    init(withNotice noticeTitle: String, andAction buttonText: String) {
        let notice = XCUIApplication().otherElements["notice_title_and_message"]

        noticeAction = XCUIApplication().buttons[buttonText]

        expectedNoticeTitle = noticeTitle

        super.init(element: notice)
    }

    func viewPublishedPost(withTitle postTitle: String) -> EditorPublishEpilogueScreen {
        // The publish notice has a joined accessibility label equal to: title + message
        // (the postTitle). It does not seem possible to target the specific postTitle label
        // only because of this.
        let expectedLabel = String(format: "%@. %@", expectedNoticeTitle, postTitle)
        XCTAssertEqual(expectedElement.label, expectedLabel, "Post title not visible on published post notice")

        noticeAction.tap()

        return EditorPublishEpilogueScreen()
    }
}
