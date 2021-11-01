import XCTest

private struct ElementStringIDs {
    static let newAccountHeader = "New Account Header"
    static let displayNameField = "Display Name Field"
    static let usernameField = "Username Field"
    static let passwordField = "Password Field"
    // This is the Done button on the Login Epilogue
    static let doneButton = "Done"
    // This is the Done button on the Signup Epilogue
    static let continueButton = "Done Button"
}

public class SignupEpilogueScreen: BaseScreen {
    let newAccountHeader: XCUIElement
    let displayNameField: XCUIElement
    let usernameField: XCUIElement
    let passwordField: XCUIElement
    let doneButton: XCUIElement
    let continueButton: XCUIElement

    init() {
        let app = XCUIApplication()
        newAccountHeader = app.staticTexts[ElementStringIDs.newAccountHeader]
        displayNameField = app.textFields[ElementStringIDs.displayNameField]
        usernameField = app.textFields[ElementStringIDs.usernameField]
        passwordField = app.secureTextFields[ElementStringIDs.passwordField]
        doneButton = app.buttons[ElementStringIDs.doneButton]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: newAccountHeader)
    }

    public func verifyEpilogueContains(username: String, displayName: String) -> SignupEpilogueScreen {
        let actualUsername = usernameField.value as! String
        let actualDisplayName = displayNameField.value as! String

        XCTAssertEqual(username, actualUsername, "Username is set to \(actualUsername) but should be \(username)")
        XCTAssertEqual(displayName, actualDisplayName, "Display name is set to \(actualDisplayName) but should be \(displayName)")

        return self
    }

    public func setPassword(_ password: String) -> SignupEpilogueScreen {
        passwordField.tap()
        passwordField.typeText(password)
        doneButton.tap()

        return self
    }

    public func continueWithSignup() -> MySiteScreen {
        continueButton.tap()

        return MySiteScreen()
    }
}
