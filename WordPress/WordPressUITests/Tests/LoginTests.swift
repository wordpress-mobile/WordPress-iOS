import UITestsFoundation
import XCTest

class LoginTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow.logoutIfNeeded()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    // Unified email login/out
    func testWPcomLoginLogout() throws {
        let prologueScreen = try PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
            .tabBar.goToMeScreen()
            .logoutToPrologue()

        XCTAssert(prologueScreen.isLoaded)
    }

    /**
     This test opens safari to trigger the mocked magic link redirect
     */
    func testEmailMagicLinkLogin() throws {
        let welcomeScreen = try WelcomeScreen().selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithLink()
            .openMagicLoginLink()
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
            .tabBar.goToMeScreen()
            .logout()

        XCTAssert(welcomeScreen.isLoaded)
    }

    // Unified self hosted login/out
    func testSelfHostedLoginLogout() throws {
        let prologueScreen = try PrologueScreen()

        try prologueScreen
            .selectSiteAddress()
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWithSelfHosted(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)
            .removeSelfHostedSite()

        XCTAssert(prologueScreen.isLoaded)
    }

    // Unified WordPress.com email login failure due to incorrect password
    func testWPcomInvalidPassword() throws {
        _ = try PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }

    // Self-Hosted after WordPress.com login.
    // Login to a WordPress.com account, open site switcher, then add a self-hosted site.
    func testAddSelfHostedSiteAfterWPcomLogin() throws {
        try PrologueScreen().selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWith(password: WPUITestCredentials.testWPcomPassword)
            .verifyEpilogueDisplays(username: WPUITestCredentials.testWPcomUsername, siteUrl: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .continueWithSelectedSite() //returns MySite screen

            // From here, bring up the sites list and choose to add a new self-hosted site.
            .showSiteSwitcher()
            .addSelfHostedSite()

            // Then, go through the self-hosted login flow:
            .proceedWith(siteUrl: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWithSelfHostedSiteAddedFromSitesList(username: WPUITestCredentials.selfHostedUsername, password: WPUITestCredentials.selfHostedPassword)

            // Login flow returns MySites modal, which needs to be closed.
            .closeModal()

            // TODO: rewrite logoutIfNeeded() to handle logging out of a self-hosted site and then WordPress.com account.
            // Currently, logoutIfNeeded() cannot handle logging out of both self-hosted and WordPress.com during tearDown().
            // So, we remove the self-hosted site before tearDown() starts.
            .removeSelfHostedSite()

        XCTAssert(MySiteScreen.isLoaded())
    }
}
