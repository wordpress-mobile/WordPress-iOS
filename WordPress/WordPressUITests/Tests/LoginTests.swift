import XCTest

class LoginTests: XCTestCase {

    override func setUp() {
        setUpTestSuite()

        LoginFlow.logoutIfNeeded()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testEmailPasswordLoginLogout() {
        let welcomeScreen = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithPassword()
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSiteAddress)
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
        let welcomeScreen = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithLink()
            .openMagicLoginLink()
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
            .tabBar.gotoMeScreen()
            .logout()

        XCTAssert(welcomeScreen.isLoaded())
    }

    func testWpcomUsernamePasswordLogin() {
        _ = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .goToSiteAddressLogin()
            .proceedWith(siteUrl: "WordPress.com")
            .proceedWith(username: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSiteAddress)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()

        XCTAssert(MySiteScreen().isLoaded())
    }

    func testSelfHostedUsernamePasswordLoginLogout() {
        _ = WelcomeScreen().selectLogin()
            .goToSiteAddressLogin()
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWith(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)
            .verifyEpilogueDisplays(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .continueWithSelectedSite()
            .removeSelfHostedSite()

        XCTAssert(WelcomeScreen().isLoaded())
    }

    func testUnsuccessfulLogin() {
        _ = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithPassword()
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
