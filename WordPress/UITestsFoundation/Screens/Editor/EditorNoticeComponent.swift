import ScreenObject
import XCTest

public class EditorNoticeComponent: ScreenObject {

    private let noticeViewTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["notice_title_and_message"]
    }

    private let noticeViewButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["View"]
    }

    var expectedNoticeTitle: String
    var noticeViewButton: XCUIElement { noticeViewButtonGetter(app) }
    var noticeViewTitle: XCUIElement { noticeViewTitleGetter(app) }

    init(
        withNotice noticeTitle: String,
        app: XCUIApplication = XCUIApplication()
    ) throws {
        expectedNoticeTitle = noticeTitle
        try super.init(
            expectedElementGetters: [ noticeViewTitleGetter ],
            app: app
        )
    }

    public func viewPublishedPost(withTitle postTitle: String) throws -> EditorPublishEpilogueScreen {
        // The publish notice has a joined accessibility label equal to: title + message
        // (the postTitle). It does not seem possible to target the specific postTitle label
        // only because of this.
        XCTAssertEqual(
            noticeViewTitle.label,
            String(format: "%@. %@", expectedNoticeTitle, postTitle),
            "Post title not visible on published post notice"
        )

        noticeViewButton.tap()
        return try EditorPublishEpilogueScreen()
    }
}
