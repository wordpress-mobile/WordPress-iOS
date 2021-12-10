import ScreenObject
import XCTest

public class SignupEpilogueScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["New Account Header"] } ],
            app: app
        )
    }

    public func verifyEpilogueContains(username: String, displayName: String) -> SignupEpilogueScreen {
        let actualUsername = app.textFields["Username Field"].value as! String
        let actualDisplayName = app.textFields["Display Name Field"].value as! String

        XCTAssertEqual(username, actualUsername, "Username is set to \(actualUsername) but should be \(username)")
        XCTAssertEqual(displayName, actualDisplayName, "Display name is set to \(actualDisplayName) but should be \(displayName)")

        return self
    }

    public func setPassword(_ password: String) -> SignupEpilogueScreen {
        let passwordField = app.secureTextFields["Password Field"]
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["Done"].tap()

        return self
    }

    public func continueWithSignup() throws -> MySiteScreen {
        app.buttons["Done Button"].tap()

        return try MySiteScreen()
    }
}
