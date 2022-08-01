import ScreenObject
import XCTest

public class SiteIntentScreen: ScreenObject {

    let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["site-intent-cancel-button"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable:next opening_brace
                { $0.tables["Site Intent Table"] },
                cancelButtonGetter
            ],
            app: app,
            waitTimeout: 7
        )
    }

    @discardableResult
    public func closeModal() throws -> MySitesScreen {
        cancelButtonGetter(app).tap()
        return try MySitesScreen()
    }

    public static func isLoaded() -> Bool {
        (try? SiteIntentScreen().isLoaded) ?? false
    }
}
