import ScreenObject
import XCTest

/// The site switcher AKA blog list. Currently presented as a modal we can get to from My Site by
/// tapping the down arrow next to the site title.
public class MySitesScreen: ScreenObject {
    let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["cancel-button"]
    }

    let plusButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-site-button"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable:next opening_brace
                { $0.staticTexts["My Sites"] },
                cancelButtonGetter,
                plusButtonGetter
            ],
            app: app
        )
    }

    public func addSelfHostedSite() throws -> LoginSiteAddressScreen {
        plusButtonGetter(app).tap()
        app.buttons["Add self-hosted site"].tap()
        return try LoginSiteAddressScreen()
    }

    public func closeModal() throws -> MySiteScreen {
        cancelButtonGetter(app).tap()
        return try MySiteScreen()
    }

    @discardableResult
    public func switchToSite(withTitle title: String) throws -> MySiteScreen {
        app.cells[title].tap()
        return try MySiteScreen()
    }
}
