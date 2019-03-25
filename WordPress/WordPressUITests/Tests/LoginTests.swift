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

    func testEmailPasswordLoginLogout() {
        let welcomeScreen = WelcomeScreen().login()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithPassword()
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
            .tabBar.gotoMeScreen()
            .logout()

        XCTAssert(welcomeScreen.isLoaded())
    }

    /**
     This test currently stops after requesting the magic link.
     The rest of the flow should be tested after we set up network mocking.
     */
    func testEmailMagicLinkLogin() {
        _ = WelcomeScreen().login()
        .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
        .proceedWithLink()
        .checkMagicLink()

        XCTAssert(LoginCheckMagicLinkScreen().isLoaded())
    }

    func testWpcomUsernamePasswordLogin() {
        _ = WelcomeScreen().login()
            .goToSiteAddressLogin()
            .proceedWith(siteUrl: "WordPress.com")
            .proceedWith(username: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()

        XCTAssert(MySiteScreen().isLoaded())
    }

    func testSelfHostedUsernamePasswordLoginLogout() {
        _ = WelcomeScreen().login()
            .goToSiteAddressLogin()
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWith(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)
            .continueWithSelectedSite()
            .removeSelfHostedSite()

        XCTAssert(WelcomeScreen().isLoaded())
    }

    func testUnsuccessfulLogin() {
        _ = WelcomeScreen().login()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithPassword()
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
