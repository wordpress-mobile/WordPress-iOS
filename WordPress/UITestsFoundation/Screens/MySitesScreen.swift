import ScreenObject
import XCTest

/// The site switcher AKA blog list. Currently presented as a modal we can get to from My Site by
/// tapping the down arrow next to the site title.
public class MySitesScreen: ScreenObject {
    let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["my-sites-cancel-button"]
    }

    let plusButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-site-button"]
    }

    let addSelfHostedSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Add self-hosted site"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable:next opening_brace
                { $0.staticTexts["My Sites"] },
                cancelButtonGetter,
                plusButtonGetter
            ],
            app: app,
            waitTimeout: 7
        )
    }

    public func addSelfHostedSite() throws -> LoginSiteAddressScreen {
        plusButtonGetter(app).tap()
        addSelfHostedSiteButtonGetter(app).tap()
        return try LoginSiteAddressScreen()
    }

    @discardableResult
    public func tapPlusButton() throws -> SiteIntentScreen {
        plusButtonGetter(app).tap()
        return try SiteIntentScreen()
    }

    @discardableResult
    public func closeModal() throws -> MySiteScreen {
        cancelButtonGetter(app).tap()
        return try MySiteScreen()
    }

    @discardableResult
    public func switchToSite(withTitle title: String) throws -> MySiteScreen {
        app.cells[title].tap()
        return try MySiteScreen()
    }

    public func closeModalIfNeeded() {
        if addSelfHostedSiteButtonGetter(app).isHittable {
            app.children(matching: .window).element(boundBy: 0).tap()
        }
        if cancelButtonGetter(app).isHittable { cancelButtonGetter(app).tap() }
    }
}
