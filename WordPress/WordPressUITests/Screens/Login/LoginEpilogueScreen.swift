import Foundation
import XCTest

private struct ElementStringIDs {
    static let headerText = "LOGGED IN AS"
    static let connectSiteButton = "connectSite"
    static let continueButton = "Continue"
}

class LoginEpilogueScreen: BaseScreen {
    let continueButton: XCUIElement
    let connectSiteButton: XCUIElement
    let headerText: XCUIElement

    init() {
        let app = XCUIApplication()
        headerText = app.otherElements[ElementStringIDs.headerText]
        connectSiteButton = app.buttons[ElementStringIDs.connectSiteButton]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: headerText)
    }

    func continueWithSelectedSite() -> MySiteScreen {
        continueButton.tap()
        return MySiteScreen()
    }

    func connectSite() {
        connectSiteButton.tap()
    }
}
