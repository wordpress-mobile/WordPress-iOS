import XCTest

extension XCTestCase {

    var app: XCUIApplication {
        get { return XCUIApplication()}
    }

     public func waitForElementToAppear(element: XCUIElement,
                                        file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectationForPredicate(existsPredicate,
                                evaluatedWithObject: element, handler: nil)

        waitForExpectationsWithTimeout(5) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 5 seconds."
                self.recordFailureWithDescription(message,
                                                  inFile: file, atLine: line, expected: true)
            }
        }
    }

    public func logoutIfNeeded() {
        if !app.textFields["Username / Email"].exists && !app.textFields["Username"].exists{
            app.tabBars["Main Navigation"].buttons["Me"].tap()
            app.tables.elementBoundByIndex(0).swipeUp()
            app.tables.cells.elementBoundByIndex(5).tap()
            app.alerts.buttons["Disconnect"].tap()
        }
    }

    public func login() {
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.oneStepUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.oneStepPassword)

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])
    }

    public func loginOther() {
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.twoStepUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.twoStepPassword)

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])
    }
}