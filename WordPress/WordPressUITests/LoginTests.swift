import XCTest

class LoginTests: XCTestCase {

    var app:XCUIApplication!

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        app = XCUIApplication()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        // Logout first if needed
        logoutIfNeeded()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        logoutIfNeeded()
        super.tearDown()
    }

    func testUnsuccessfulLogin() {
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText("unknow@unknow.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("failpassword")

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.staticTexts["Sorry, we can't log you in."])

        app.buttons["OK"].tap()
    }

    func testSimpleLogin() {
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.oneStepUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.oneStepPassword)

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])
    }


    func testTwoStepLogin() {
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.twoStepUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.twoStepPassword)

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])
    }

    func testSelfHostedLoginWithoutJetPack() {
        app.buttons["Add Self-Hosted Site"].tap()

        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.selfHostedUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.selfHostedPassword)

        let siteURLTextField = app.textFields["Site Address (URL)"]
        siteURLTextField.tap()
        siteURLTextField.typeText(WordPressTestCredentials.selfHostedSiteURL)

        app.buttons["Add Site"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])

        app.tabBars["Main Navigation"].buttons["My Sites"].tap()

        app.tabBars["Main Navigation"].buttons["My Sites"].tap()

        let cellName = WordPressTestCredentials.selfHostedSiteName
        app.tables.cells.staticTexts[cellName].tap()

        app.tables.elementBoundByIndex(0).swipeUp()

        app.tables.cells.staticTexts["Settings"].tap()

        app.tables.elementBoundByIndex(0).swipeUp()

        app.tables.cells.staticTexts["Remove Site"].tap()

        app.buttons["Remove Site"].tap()
    }

    func testCreateAccount() {
        let username = "\(WordPressTestCredentials.oneStepUser)\(arc4random())"
        app.buttons["Create Account"].tap()

        let emailAddressField = app.textFields["Email Address"]
        emailAddressField.tap()
        emailAddressField.typeText("\(username)@gmail.com")

        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText(username)

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(WordPressTestCredentials.oneStepPassword)
    }
}
