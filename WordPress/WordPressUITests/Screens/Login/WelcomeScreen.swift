import Foundation
import XCTest

class WelcomeScreen: BaseScreen {
    let logInButton: XCUIElement
    let createNewSiteButton: XCUIElement

    init() {
        logInButton = XCUIApplication().buttons["Log In"]
        createNewSiteButton = XCUIApplication().buttons["nextButton"]
        super.init(element: logInButton)
    }

    func login() -> LoginEmailScreen {
        logInButton.tap()

        return LoginEmailScreen()
    }

    func createNewSite() -> SignupScreen {
        createNewSiteButton.tap()
        return SignupScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["nextButton"].exists
    }
}
