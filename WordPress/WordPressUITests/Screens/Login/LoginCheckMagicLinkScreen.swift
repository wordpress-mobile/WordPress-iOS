import Foundation
import XCTest

private struct ElementStringIDs {
    static let passwordOption = "Enter your password instead."
    static let mailButton = "Open Mail"
    static let mailAlert = "Please check your email"
    static let okButton = "OK"
}

class LoginCheckMagicLinkScreen: BaseScreen {
    let passwordOption: XCUIElement
    let mailButton: XCUIElement
    let mailAlert: XCUIElement

    init() {
        let app = XCUIApplication()
        passwordOption = app.buttons[ElementStringIDs.passwordOption]
        mailButton = app.buttons[ElementStringIDs.mailButton]
        mailAlert = app.alerts[ElementStringIDs.mailAlert]

        super.init(element: mailButton)
    }

    func proceedWithPassword() -> LoginPasswordScreen {
        passwordOption.tap()

        return LoginPasswordScreen()
    }

    func checkMagicLink() -> LoginCheckMagicLinkScreen {
        mailButton.tap()
        mailAlert.buttons[ElementStringIDs.okButton].tap()

        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.mailButton].exists
    }
}
