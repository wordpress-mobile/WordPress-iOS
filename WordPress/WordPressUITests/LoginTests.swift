import XCTest

class LoginTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        XCUIApplication().launch()
        BaseScreen.testCase = self

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
}
