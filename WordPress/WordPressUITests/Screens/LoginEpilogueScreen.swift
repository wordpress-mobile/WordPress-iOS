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

    func continueWithSelectedSite() -> MySitesScreen {
        continueButton.tap()
        return MySitesScreen.init()
    }

    func connectSite() {
        connectSiteButton.tap()
    }
}
