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

    // Unified WordPress.com login
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

    // Self-Hosted after WordPress.com login.
    // Login to a WordPress.com account, open site switcher, then add a self-hosted site.
    func testAddSelfHostedSiteAfterWPcomLogin() {
        PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .continueWithSelectedSite() //returns MySite screen

            // From here, bring up the sites list and choose to add a new self-hosted site.
            .showSiteSwitcher()
            .addSelfHostedSite()

            // Then, go through the self-hosted login flow:
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWith(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)
            .verifyEpilogueDisplays(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .continueWithSelfHostedSiteAddedFromSitesList()

            // Login flow returns MySites modal, which needs to be closed.
            .closeModal()

            // TODO: rewrite logoutIfNeeded() to handle logging out of a self-hosted site and then WordPress.com account.
            // Currently, logoutIfNeeded() cannot handle logging out of both self-hosted and WordPress.com during tearDown().
            // So, we remove the self-hosted site before tearDown() starts.
            .removeSelfHostedSite()

        XCTAssert(MySiteScreen().isLoaded())
    }
}
