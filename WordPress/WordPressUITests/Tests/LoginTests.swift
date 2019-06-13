import XCTest

class LoginTests: XCTestCase {

    override func setUp() {
        setUpTestSuite()

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
     This test opens safari to trigger the mocked magic link redirect
     */
    func testEmailMagicLinkLogin() {
        let welcomeScreen = WelcomeScreen().login()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithLink()
            .openMagicLink()
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
            .tabBar.gotoMeScreen()
            .logout()

        XCTAssert(welcomeScreen.isLoaded())
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
