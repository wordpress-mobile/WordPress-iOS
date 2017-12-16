import Foundation
import XCTest

//app.tables/*@START_MENU_TOKEN@*/.staticTexts["LOGGED IN AS"]/*[[".otherElements[\"LOGGED IN AS\"].staticTexts[\"LOGGED IN AS\"]",".staticTexts[\"LOGGED IN AS\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

class LoginEpilogueScreen: BaseScreen {
//        app.alerts["“WordPress” Would Like to Send You Notifications"].buttons["Don’t Allow"].tap()
//        app.tables/*@START_MENU_TOKEN@*/.staticTexts["LOGGED IN AS"]/*[[".otherElements[\"LOGGED IN AS\"].staticTexts[\"LOGGED IN AS\"]",".staticTexts[\"LOGGED IN AS\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app.alerts["“WordPress” Would Like to Send You Notifications"].buttons["Allow"].tap()
//        app.buttons["Connect another site"].tap()
//        app.buttons["Continue"].tap()
    let continueButton: XCUIElement
    let connectSiteButton: XCUIElement
    init() {
        let app = XCUIApplication()
        let headerElement = app.otherElements["LOGGED IN AS"]
        connectSiteButton = app.buttons["Connect another site"]
        continueButton = app.buttons["Continue"]

        super.init(element: headerElement)
    }

    func continueWithSelectedSite() -> MySitesScreen {
        continueButton.tap()
        return MySitesScreen.init()
    }

    func connectSite() {
        connectSiteButton.tap()
    }
}
