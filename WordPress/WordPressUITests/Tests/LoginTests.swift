import XCTest

class LoginTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["NoAnimations"]
        app.activate()

        // Logout first if needed
        LoginFlow.logoutIfNeeded()
    }

    override func tearDown() {
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testSimpleLoginLogout() {
        let welcomeScreen = WelcomeScreen().login()
            .proceedWith(email: WPUITestCredentials.testUserEmail)
            .proceedWithPassword()
            .proceedWith(password: WPUITestCredentials.testUserPassword)
            .continueWithSelectedSite()
            .tabBar.gotoMeScreen()
            .logout()

        XCTAssert(welcomeScreen.isLoaded())
    }

    func testUnsuccessfulLogin() {
        _ = WelcomeScreen().login()
            .proceedWith(email: WPUITestCredentials.testUserEmail)
            .proceedWithPassword()
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
