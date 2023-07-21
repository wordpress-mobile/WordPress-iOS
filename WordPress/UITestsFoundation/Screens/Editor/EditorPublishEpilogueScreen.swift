import ScreenObject
import XCTest

public class EditorPublishEpilogueScreen: ScreenObject {

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["doneButton"]
    }

    private let viewButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["viewPostButton"]
    }

    private let publishedPostStatusLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["publishedPostStatusLabel"]
    }

    private let postTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["postTitle"]
    }

    private let siteUrlGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["siteUrl"]
    }

    var doneButton: XCUIElement { doneButtonGetter(app) }
    var postTitle: XCUIElement { postTitleGetter(app) }
    var publishedPostStatusLabel: XCUIElement { publishedPostStatusLabelGetter(app) }
    var siteUrl: XCUIElement { siteUrlGetter(app) }
    var viewButton: XCUIElement { viewButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ doneButtonGetter, viewButtonGetter, publishedPostStatusLabelGetter ],
            app: app
        )
    }

    /// - Note: Returns `Void` since the return screen depends on which screen we started from.
    public func tapDone() {
        doneButton.tap()
    }

    public func verifyEpilogueDisplays(postTitle expectedPostTitle: String, siteAddress expectedSiteAddress: String) -> EditorPublishEpilogueScreen {
        let actualPostTitle = postTitle.label
        let actualSiteUrl = siteUrl.label

        XCTAssertEqual(expectedPostTitle, actualPostTitle, "Post title doesn't match expected title")
        XCTAssertEqual(expectedSiteAddress, actualSiteUrl, "Site address doesn't match expected address")

        return self
    }
}
