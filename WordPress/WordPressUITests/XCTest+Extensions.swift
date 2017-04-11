import XCTest

public struct elementStringIDs {
    // General
    static var mainNavigationBar = "Main Navigation"
    static var mainNavigationMeButton = "meTabButton"
    static var mainNavigationMySitesButton = "mySitesTabButton"
    static var mainNavigationNewPostButton = "New Post"

    // Login page
    static var loginUsernameField = "Email or username"
    static var loginPasswordField = "Password"
    static var loginNextButton = "Next Button"
    static var loginSubmitButton = "Log In Button"
    static var addSelfHostedButton = "addSelfHostedButton"
    static var selfHostedURLField = "selfHostedURL"
    static var createSiteButton = "createSiteButton"

    // Add site login page
    static var addSiteLoginUsernameField = "usernameField"
    static var addSiteLoginPasswordField = "passwordField"
    static var addSiteSubmitButton = "submitButton"

    // Signup page
    static var nuxUsernameField = "nuxUsernameField"
    static var nuxEmailField = "nuxEmailField"
    static var nuxPasswordField = "nuxPasswordField"
    static var nuxUrlField = "nuxUrlField"
    static var nuxCreateAccountButton = "nuxCreateAccountButton"

    // My Sites page
    static var settingsButton = "BlogDetailsSettingsCell"
    static var removeSiteButton = "BlogDetailsRemoveSiteCell"

    // Me tab
    static var appSettingsButton = "appSettingsButton"
    static var logOutFromWPcomButton = "logOutFromWPcomButton"

    // App Settings Page
    static var aztecEditorToggle = "nativeEditorToggle"

    // Aztec Editor
    static var aztecPostView = "WordPress.AztecPostView"
    static var editorCloseButton = "editorCloseButton"
    static var richTextField = "editorRichContentView"
    static var htmlTextField = "editorHTMLContentView"
    static var richTextContentLabel = "editorContentPlaceholder"

    // Aztec Editor Toolbar
    static var mediaButton = "formatToolbarInsertMedia"
    static var headerButton = "formatToolbarSelectParagraphStyle"
    static var boldButton = "formatToolbarToggleBold"
    static var italicButton = "formatToolbarToggleItalic"
    static var underlineButton = "formatToolbarToggleUnderline"
    static var strikethroughButton = "formatToolbarToggleStrikethrough"
    static var blockquoteButton = "formatToolbarToggleBlockquote"
    static var orderedlistButton = "formatToolbarToggleListOrdered"
    static var unorderedlistButton = "formatToolbarToggleListUnordered"
    static var linkButton = "formatToolbarInsertLink"
    static var horizontalrulerButton = "formatToolbarInsertHorizontalRuler"
    static var sourcecodeButton = "formatToolbarToggleHtmlView"
    static var moreButton = "formatToolbarInsertMore"
    // Accessibility identifiers for header options
    //static var header1Button = "formatToolbarToggleH1"
    //static var header2Button = "formatToolbarToggleH2"
    //static var header3Button = "formatToolbarToggleH3"
    //static var header4Button = "formatToolbarToggleH4"
    //static var header5Button = "formatToolbarToggleH5"
    //static var header6Button = "formatToolbarToggleH6"
    static var header1Button = "Heading 1"
    static var header2Button = "Heading 2"
    static var header3Button = "Heading 3"
    static var header4Button = "Heading 4"
    static var header5Button = "Heading 5"
    static var header6Button = "Heading 6"
}

extension XCUIElement {
    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(text: String) -> Void {
        let app = XCUIApplication()

        if (self.value as! String).characters.count > 0 {
            self.press(forDuration: 1.2)
            app.menuItems["Select All"].tap()
        } else {
            self.tap()
        }

        self.typeText(text)
    }

    /**
     Enters text in the field and then selects all entered text
     - Parameter text: the text to enter into the field
    */
    func enterAndSelectText(text: String) -> Void {
        let app = XCUIApplication()

        self.typeText(text)
        self.press(forDuration: 1.2)
        app.menuItems.element(boundBy: 1).tap()
    }

    /**
 public func typeAndSelectText(text: String) {
 let app = XCUIApplication()
 let richContentTextView = app.textViews[ elementStringIDs.richTextField ]
 
 app.staticTexts[ elementStringIDs.richTextContentLabel ].tap()
 richContentTextView.typeText(text)
 richContentTextView.press(forDuration: 1.2)
 app.menuItems.element(boundBy: 1).tap()
 }*/
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
            app.tables.cells[ elementStringIDs.logOutFromWPcomButton ].tap()
            app.alerts.buttons.element(boundBy: 1).tap()
            //Give some time to everything get proper saved.
            sleep(2)
        }
    }

    public func loginIfNeeded(username: String, password: String) {
        let app = XCUIApplication()
        if app.textFields[ elementStringIDs.loginUsernameField ].exists {
            simpleLogin(username: username, password: password)
            //Give time for login to finish.
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

        // Tap the My Sites button twice to be sure that we're on the All Sites list
        mySitesTabButton.tap()
        mySitesTabButton.tap()

        siteNameField.tap()
        app.tables.element(boundBy: 0).swipeUp()

        waitForElementToAppear(element: removeButton)
        removeButton.tap()

        if ( isIpad(app: app) ) {
            app.alerts.buttons.element(boundBy: 1).tap()
        } else {
            app.sheets.buttons.element(boundBy: 0).tap()
        }
    }

    public func createAccount(email: String, username: String, password: String, url: String? = nil) {
        let app = XCUIApplication()
        let createSiteFromLoginScreenButton = app.buttons[ elementStringIDs.createSiteButton ]
        let emailField = app.textFields[ elementStringIDs.nuxEmailField ]
        let usernameField = app.textFields[ elementStringIDs.nuxUsernameField ]
        let passwordField = app.secureTextFields[ elementStringIDs.nuxPasswordField ]
        let urlField = app.textFields[ elementStringIDs.nuxUrlField ]
        let createAccountButton = app.buttons[ elementStringIDs.nuxCreateAccountButton ]

        if createSiteFromLoginScreenButton.exists {
            createSiteFromLoginScreenButton.tap()
        }

        waitForElementToAppear(element: emailField)

        emailField.tap()
        emailField.clearAndEnterText(text: email)
        usernameField.tap()
        usernameField.clearAndEnterText(text: username)
        passwordField.tap()
        passwordField.clearAndEnterText(text: password)

        if ( url != nil ) {
            urlField.tap()
            urlField.clearAndEnterText(text: url!)
        }

        createAccountButton.tap()
    }

    public func swipeAndSelectHeaderStyle(headerStyle: String) {
        let app = XCUIApplication()

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
        if ( isIpad(app: app) ) {
            app.tables.element(boundBy: 2).swipeUp()
        } else {
            app.tables.element(boundBy: 1).swipeUp()
        }
        app.tables.staticTexts[ headerStyle ].tap()
    }

    public func insertLink(link: String) {
        let app = XCUIApplication()

        // Prepare link to be auto-filled in URL field
        UIPasteboard.general.string = link

        app.scrollViews.otherElements.buttons[ elementStringIDs.linkButton ].tap()

        if ( isIpad(app: app) ) {
            app.alerts.buttons.element(boundBy: 2).tap()
        } else {
            app.alerts.buttons.element(boundBy: 3).tap()
        }
    }
}
