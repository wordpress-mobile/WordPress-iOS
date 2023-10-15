import ScreenObject
import XCTest

/// The site switcher AKA blog list. Currently presented as a modal we can get to from My Site by
/// tapping the down arrow next to the site title.
public class MySitesScreen: ScreenObject {

    private let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["my-sites-cancel-button"]
    }

    private let plusButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-site-button"]
    }

    private let addSelfHostedSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Add self-hosted site"]
    }

    private let mySitesLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["My Sites"]
    }

    var addSelfHostedSiteButton: XCUIElement { addSelfHostedSiteButtonGetter(app) }
    var cancelButton: XCUIElement { cancelButtonGetter(app) }
    var mySitesLabel: XCUIElement { mySitesLabelGetter(app) }
    var plusButton: XCUIElement { plusButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                mySitesLabelGetter,
                cancelButtonGetter,
                plusButtonGetter
            ],
            app: app
        )
    }

    public func addSelfHostedSite() throws -> LoginSiteAddressScreen {
        plusButton.tap()
        addSelfHostedSiteButton.tap()
        return try LoginSiteAddressScreen()
    }

    @discardableResult
    public func tapPlusButton() throws -> SiteIntentScreen {
        plusButton.tap()
        return try SiteIntentScreen()
    }

    @discardableResult
    public func closeModal() throws -> MySiteScreen {
        cancelButton.tap()
        return try MySiteScreen()
    }

    @discardableResult
    public func switchToSite(withTitle title: String) throws -> MySiteMoreMenuScreen {
        app.cells[title].tap()
        return try MySiteMoreMenuScreen()
    }

    public func closeModalIfNeeded() {
        if addSelfHostedSiteButtonGetter(app).isHittable {
            app.children(matching: .window).element(boundBy: 0).tap()
        }
        if cancelButton.isHittable { cancelButton.tap() }
    }
}
