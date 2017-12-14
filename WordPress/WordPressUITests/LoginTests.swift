import XCTest

class LoginTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        XCUIApplication().launch()
        app = XCUIApplication()

        // Logout first if needed
        logoutIfNeeded()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        logoutIfNeeded()
        super.tearDown()
    }

    func testSimpleLoginLogout() {
        let welcomeScreen = WelcomeScreen.init().login()
            .proceedWith(email: WPUITestCredentials.testUserEmail)
            .proceedWithPassword()
            .proceedWith(password: WPUITestCredentials.testUserPassword)
            .continueWithSelectedSite()
            .tabBar.gotoMeScreen()
            .logout()

        XCTAssert(welcomeScreen.isLoaded())
    }

    func testUnsuccessfulLogin() {
        _ = WelcomeScreen.init().login()
            .proceedWith(email: WPUITestCredentials.testUserEmail)
            .proceedWithPassword()
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }

//    func testSelfHostedLoginWithoutJetPack() {
//        loginSelfHosted(username: WordPressTestCredentials.selfHostedUser, password: WordPressTestCredentials.selfHostedPassword, url: WordPressTestCredentials.selfHostedSiteURL)
//
//        waitForElementToAppear(element: app.tabBars[ elementStringIDs.mainNavigationBar ], timeout: 10)
//
//        logoutSelfHosted()
//    }
//
//    func testCreateAccount() {
//        let username = "\(WordPressTestCredentials.oneStepUser)\(arc4random())"
//        let email = WordPressTestCredentials.nuxEmailPrefix + username + WordPressTestCredentials.nuxEmailSuffix
//
//        createAccount(email: email, username: username, password: WordPressTestCredentials.oneStepPassword)
//        waitForElementToAppear(element: app.tabBars[ elementStringIDs.mainNavigationBar ], timeout: 20)
//    }
}
