import ScreenObject
import XCTest

public class EditorNoticeComponent: ScreenObject {

    private let noticeTitleGetter: (XCUIApplication) -> XCUIElement
    private let noticeActionGetter: (XCUIApplication) -> XCUIElement

    private let expectedNoticeTitle: String

    init(
        withNotice noticeTitle: String,
        andAction buttonText: String,
        app: XCUIApplication = XCUIApplication()
    ) throws {
        noticeTitleGetter = { app in app.otherElements["notice_title_and_message"] }
        noticeActionGetter = { app in app.buttons[buttonText] }
        expectedNoticeTitle = noticeTitle

        try super.init(
            expectedElementGetters: [ noticeTitleGetter, noticeActionGetter ],
            app: app
        )
    }

    public func viewPublishedPost(withTitle postTitle: String) throws -> EditorPublishEpilogueScreen {
        // The publish notice has a joined accessibility label equal to: title + message
        // (the postTitle). It does not seem possible to target the specific postTitle label
        // only because of this.
        XCTAssertEqual(
            noticeTitleGetter(app).label,
            String(format: "%@. %@", expectedNoticeTitle, postTitle),
            "Post title not visible on published post notice"
        )

        noticeActionGetter(app).tap()

        return try EditorPublishEpilogueScreen()
    }
}
