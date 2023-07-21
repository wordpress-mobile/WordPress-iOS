import ScreenObject
import XCTest

public class SiteIntentScreen: ScreenObject {

    private let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["site-intent-cancel-button"]
    }

    private let siteIntentTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["Site Intent Table"]
    }

    var cancelButton: XCUIElement { cancelButtonGetter(app) }
    var siteIntentTable: XCUIElement { siteIntentTableGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                siteIntentTableGetter,
                cancelButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func closeModal() throws -> MySitesScreen {
        cancelButton.tap()
        return try MySitesScreen()
    }

    public static func isLoaded() -> Bool {
        (try? SiteIntentScreen().isLoaded) ?? false
    }
}
