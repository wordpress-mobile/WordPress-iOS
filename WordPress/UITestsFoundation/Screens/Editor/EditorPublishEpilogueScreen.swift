import ScreenObject
import XCTest

public class EditorPublishEpilogueScreen: ScreenObject {

    private let getDoneButton: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["doneButton"]
    }

    private let getViewButton: (XCUIApplication) -> XCUIElement = {
        $0.buttons["viewPostButton"]
    }

    var doneButton: XCUIElement { getDoneButton(app) }
    var viewButton: XCUIElement { getViewButton(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // Defining this via a `let` rather than inline only to avoid a SwiftLint style violation
        let publishedPostStatusGetter: (XCUIApplication) -> XCUIElement = {
            $0.staticTexts["publishedPostStatusLabel"]
        }

        try super.init(
            expectedElementGetters: [ getDoneButton, getViewButton, publishedPostStatusGetter ],
            app: app
        )
    }

    /// - Note: Returns `Void` since the return screen depends on which screen we started from.
    public func done() {
        doneButton.tap()
    }

    public func verifyEpilogueDisplays(postTitle expectedPostTitle: String, siteAddress expectedSiteAddress: String) -> EditorPublishEpilogueScreen {
        let actualPostTitle = app.staticTexts["postTitle"].label
        let actualSiteAddress = app.staticTexts["siteUrl"].label

        XCTAssertEqual(expectedPostTitle, actualPostTitle, "Post title doesn't match expected title")
        XCTAssertEqual(expectedSiteAddress, actualSiteAddress, "Site address doesn't match expected address")

        return self
    }
}
