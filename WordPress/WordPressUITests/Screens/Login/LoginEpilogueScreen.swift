import Foundation
import XCTest

class LoginEpilogueScreen: BaseScreen {
    let continueButton: XCUIElement
    let connectSiteButton: XCUIElement
    let headerText: XCUIElement

    init() {
        let app = XCUIApplication()
        headerText = app.otherElements["LOGGED IN AS"]
        connectSiteButton = app.buttons["Connect another site"]
        continueButton = app.buttons["Continue"]

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
