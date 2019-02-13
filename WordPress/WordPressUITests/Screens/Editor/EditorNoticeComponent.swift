import Foundation
import XCTest

class EditorNoticeComponent: BaseScreen {
    let noticeAction: XCUIElement

    init(withNotice noticeText: String, andAction buttonText: String) {
        let notice = XCUIApplication().staticTexts[noticeText]
        noticeAction = XCUIApplication().buttons[buttonText]

        super.init(element: notice)
    }

    func viewPublishedPost() -> EditorPublishEpilogueScreen {
        let expectedAction = XCUIApplication().buttons["View"]
        XCTAssertEqual(noticeAction, expectedAction)

        noticeAction.tap()

        return EditorPublishEpilogueScreen()
    }
}
