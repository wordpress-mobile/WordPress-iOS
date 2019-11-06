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
        XCTAssert(XCUIApplication().staticTexts[postTitle].exists, "Post title not visible on published post notice")
        noticeAction.tap()

        return EditorPublishEpilogueScreen()
    }
}
