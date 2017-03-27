import XCTest

public struct elementStringIDs {
    // General
    static var mainNavigationBar = "Main Navigation"
    static var mainNavigationMeButton = "meTabButton"
    static var mainNavigationMySitesButton = "mySitesTabButton"

    // Login page
    static var loginUsernameField = "Email or username"
    static var loginPasswordField = "Password"
    static var loginNextButton = "Next Button"
    static var loginSubmitButton = "Log In Button"
    static var addSelfHostedButton = "addSelfHostedButton"
    static var selfHostedURLField = "selfHostedURL"

    // Add site login page
    static var addSiteLoginUsernameField = "usernameField"
    static var addSiteLoginPasswordField = "passwordField"
    static var addSiteSubmitButton = "submitButton"

    // Signup page
    static var nuxUsernameField = "nuxUsernameField"

    // My Sites page
    static var settingsButton = "BlogDetailsSettingsCell"

    // Site Settings page
    static var removeSiteButton = "removeSiteButton"

    // Me tab
    static var disconnectFromWPcomButton = "disconnectFromWPcomButton"
}

extension XCTestCase {

     public func waitForElementToAppear(element: XCUIElement,
                                        file: String = #file, line: UInt = #line, timeout: Int? = nil) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate,
                    evaluatedWith: element, handler: nil)

        let timeoutValue = timeout ?? 5

        waitForExpectations(timeout: TimeInterval(timeoutValue)) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after \(timeoutValue) seconds."
                self.recordFailure(withDescription: message,
                                                  inFile: file, atLine: line, expected: true)
            }
        }
    }

    private func isIpad(app: XCUIApplication) -> Bool {
        return app.windows.element(boundBy: 0).horizontalSizeClass == .regular && app.windows.element(boundBy: 0).verticalSizeClass == .regular
    }


    // Need to add attempt to sign out of self-hosted as well
    public func logoutIfNeeded() {
        let app = XCUIApplication()
        if !app.textFields[ elementStringIDs.loginUsernameField ].exists && !app.textFields[ elementStringIDs.nuxUsernameField ].exists {
            app.tabBars[ elementStringIDs.mainNavigationBar ].buttons[ elementStringIDs.mainNavigationMeButton ].tap()
            app.tables.element(boundBy: 0).swipeUp()
            app.tables.cells[ elementStringIDs.disconnectFromWPcomButton ].tap()
            app.alerts.buttons.element(boundBy: 1).tap()
            //Give some time to everything get proper saved.
            sleep(2)
        }
    }

    public func simpleLogin(username: String, password: String) {
        let app = XCUIApplication()

        let emailOrUsernameTextField = app.textFields[ elementStringIDs.loginUsernameField ]
        emailOrUsernameTextField.tap()
        emailOrUsernameTextField.typeText( username )

        let nextButton = app.buttons[ elementStringIDs.loginNextButton ]
        if ( nextButton.exists ) {
            nextButton.tap()
        }

        let passwordSecureTextField = app.secureTextFields[ elementStringIDs.loginPasswordField ]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText( password )
        app.buttons[ elementStringIDs.loginSubmitButton ].tap()
    }

    public func addSiteLogin(username: String, password: String) {
        let app = XCUIApplication()
        let emailOrUsernameTextField = app.textFields[ elementStringIDs.addSiteLoginUsernameField ]
        emailOrUsernameTextField.tap()
        emailOrUsernameTextField.typeText( username )

        let nextButton = app.buttons[ elementStringIDs.loginNextButton ]
        if ( nextButton.exists ) {
            nextButton.tap()
        }

        let passwordSecureTextField = app.secureTextFields[ elementStringIDs.addSiteLoginPasswordField ]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText( password )
        app.buttons[ elementStringIDs.addSiteSubmitButton ].tap()
    }

    public func loginSelfHosted(username: String, password: String, url: String) {
        let app = XCUIApplication()

        app.buttons[ elementStringIDs.addSelfHostedButton ].tap()

        let selfHostedURLField = app.textFields[ elementStringIDs.selfHostedURLField ]
        selfHostedURLField.tap()
        selfHostedURLField.typeText( url )

        addSiteLogin( username: username, password: password )
    }

    public func logoutSelfHosted() {
        let app = XCUIApplication()

        let removeButton = app.tables.cells[ elementStringIDs.removeSiteButton ]
        let mySitesTabButton = app.tabBars[ elementStringIDs.mainNavigationBar ].buttons[ elementStringIDs.mainNavigationMySitesButton ]
        let siteNameField = app.tables.staticTexts[ WordPressTestCredentials.selfHostedSiteName ]
        let settingsButton = app.tables.cells[ elementStringIDs.settingsButton ]

        // Tap the My Sites button twice to be sure that we're on the All Sites list
        mySitesTabButton.tap()
        mySitesTabButton.tap()

        siteNameField.tap()
        settingsButton.tap()

        waitForElementToAppear(element: removeButton)
        removeButton.tap()

        if ( isIpad(app: app) ) {
            app.alerts.buttons.element(boundBy: 1).tap()
        } else {
            app.sheets.buttons.element(boundBy: 0).tap()
        }
    }
}
