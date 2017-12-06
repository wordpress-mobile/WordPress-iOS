import Foundation
import XCTest

class LoginEmailScreen: BaseScreen {
    //        app.navigationBars["WordPress.LoginEmailView"].buttons["Back"].tap()
//    let emailAddressTextField = app.textFields["Email address"]
//    emailAddressTextField.typeText("brbrrtest1@gmail.com")
//
//    let nextButtonButton = app.buttons["Next Button"]
//    nextButtonButton.tap()

    let emailTextField: XCUIElement
    let nextButton: XCUIElement
    init() {
        emailTextField = XCUIApplication().textFields["Email address"]
        nextButton = XCUIApplication().buttons["Next Button"]

        super.init(element: emailTextField)
    }

    func proceedWith(email: String) -> LinkOrPasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return LinkOrPasswordScreen.init()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["Log In Button"].exists
    }

}
