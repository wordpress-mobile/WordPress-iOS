import Foundation
import XCTest

private struct ElementStringIDs {
    static let loginButton = "Prologue Log In Button"
    static let createNewSiteButton = "nextButton"
}

class WelcomeScreen: BaseScreen {
    let logInButton: XCUIElement
    let createNewSiteButton: XCUIElement

    init() {
        logInButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        createNewSiteButton = XCUIApplication().buttons[ElementStringIDs.createNewSiteButton]

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
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
