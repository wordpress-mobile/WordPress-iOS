import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let blogsTable = "Blogs"
    static let cancelButton = "cancel-button"
    static let plusButton = "add-site-button"
    static let addSelfHostedSiteButton = "Add self-hosted site"
}

/// The site switcher aka blog list. In the app, it's a modal we can get to from My Site by tapping the down arrow next to the site title.
class MySitesScreen: BaseScreen {
    let blogsTable: XCUIElement
    let cancelButton: XCUIElement
    let plusButton: XCUIElement
    let addSelfHostedSiteButton: XCUIElement

    init() {
        let app = XCUIApplication()
        blogsTable = app.staticTexts[ElementStringIDs.blogsTable]
        cancelButton = app.buttons[ElementStringIDs.cancelButton]
        plusButton = app.buttons[ElementStringIDs.plusButton]
        addSelfHostedSiteButton = app.buttons[ElementStringIDs.addSelfHostedSiteButton]

        super.init(element: plusButton)
    }

    func addSelfHostedSite() -> LoginSiteAddressScreen {
        plusButton.tap()
        addSelfHostedSiteButton.tap()
        return LoginSiteAddressScreen()
    }

    func closeModal() -> MySiteScreen {
        cancelButton.tap()
        return MySiteScreen()
    }

    @discardableResult
    func switchToSite(withTitle title: String) -> MySiteScreen {
        XCUIApplication().cells[title].tap()
        return MySiteScreen()
    }
}
