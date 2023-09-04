import ScreenObject
import XCTest

public class QuickStartCustomizeScreen: ScreenObject {

    private let customizeSiteHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Customize Your Site"]
    }

    private let createSiteLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Create your site"]
    }

    private let checkSiteTitleLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Check your site title"]
    }

    private let chooseSiteIconLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Choose a unique site icon"]
    }

    private let reviewSitePagesLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Review site pages"]
    }

    private let viewSiteLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["View your site"]
    }

    var checkSiteTitleLabel: XCUIElement { checkSiteTitleLabelGetter(app) }
    var chooseSiteIconLabel: XCUIElement { chooseSiteIconLabelGetter(app) }
    var createSiteLabel: XCUIElement { createSiteLabelGetter(app) }
    var customizeSiteHeader: XCUIElement { customizeSiteHeaderGetter(app) }
    var reviewSitePagesLabel: XCUIElement { reviewSitePagesLabelGetter(app) }
    var viewSiteLabel: XCUIElement { viewSiteLabelGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ customizeSiteHeaderGetter ],
            app: app
        )
    }

    public func verifyCustomizeSiteListDisplayed(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(customizeSiteHeader.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertTrue(createSiteLabel.exists, file: file, line: line)
        XCTAssertTrue(checkSiteTitleLabel.exists, file: file, line: line)
        XCTAssertTrue(chooseSiteIconLabel.exists, file: file, line: line)
        XCTAssertTrue(reviewSitePagesLabel.exists, file: file, line: line)
        XCTAssertTrue(viewSiteLabel.exists, file: file, line: line)

        return self
    }

    public func tapCheckSiteTitle() throws -> MySiteScreen {
        checkSiteTitleLabel.tap()

        return try MySiteScreen()
    }
}
