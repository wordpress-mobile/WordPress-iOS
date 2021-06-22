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

    // Unified email login/out
    // Replaces testEmailPasswordLoginLogout
    func testWordPressLoginLogout() {
        let prologueScreen = PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
            .tabBar.gotoMeScreen()
            .logoutToPrologue()

        XCTAssert(prologueScreen.isLoaded())
    }

    // Old email login/out
    // TODO: remove when unifiedAuth is permanent.
    func testEmailPasswordLoginLogout() {
        let welcomeScreen = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithPassword()
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
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

    // Unified WordPress.com login/out
    // Replaces testWpcomUsernamePasswordLogin
    func testWPcomLogin() {
        _ = PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()

        XCTAssert(MySiteScreen().isLoaded())
    }

    // Old WordPress.com login/out
    // TODO: remove when unifiedAuth is permanent.
    func testWpcomUsernamePasswordLogin() {
        _ = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .goToSiteAddressLogin()
            .proceedWith(siteUrl: "WordPress.com")
            .proceedWith(username: WPUITestCredentials.testWPcomSitePrimaryAddress, password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()

        XCTAssert(MySiteScreen().isLoaded())
    }

    // Unified self hosted login/out
    // Replaces testSelfHostedUsernamePasswordLoginLogout
    func testSelfHostedLoginLogout() {
        PrologueScreen().selectSiteAddress()
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWith(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)
            .verifyEpilogueDisplays(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .continueWithSelectedSite()
            .removeSelfHostedSite()

        XCTAssert(PrologueScreen().isLoaded())
    }

    // Old self hosted login/out
    // TODO: remove when unifiedAuth is permanent.
    func testSelfHostedUsernamePasswordLoginLogout() {
        WelcomeScreen().selectLogin()
            .goToSiteAddressLogin()
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWith(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)
            .verifyEpilogueDisplays(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .continueWithSelectedSite()
            .removeSelfHostedSite()

        XCTAssert(WelcomeScreen().isLoaded())
    }

    // Unified WordPress.com email login failure due to incorrect password
    // Replaces testUnsuccessfulLogin
    func testWPcomInvalidPassword() {
        _ = PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }

    // Old email login fail
    // TODO: remove when unifiedAuth is permanent.
    func testUnsuccessfulLogin() {
        _ = WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithPassword()
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
