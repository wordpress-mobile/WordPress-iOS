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

    public func verifyCustomizeSiteListDisplayed() -> Self {
        XCTAssertTrue(customizeSiteHeader.waitForExistence(timeout: 10))
        XCTAssertTrue(createSiteLabel.exists)
        XCTAssertTrue(checkSiteTitleLabel.exists)
        XCTAssertTrue(chooseSiteIconLabel.exists)
        XCTAssertTrue(reviewSitePagesLabel.exists)
        XCTAssertTrue(viewSiteLabel.exists)

        return self
    }

    public func tapCheckSiteTitle() throws -> MySiteScreen {
        checkSiteTitleLabel.tap()

        return try MySiteScreen()
    }
}
