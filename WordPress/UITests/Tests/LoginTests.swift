import UITestsFoundation
import XCTest

class LoginTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    // Unified email login/out
    func testWPcomLoginLogout() throws {
        try PrologueScreen()
            .selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithValidPassword()
            .verifyEpilogueDisplays(
                username: WPUITestCredentials.testWPcomUsername,
                siteUrl: WPUITestCredentials.testWPcomPaidSite
            )
            .continueWithSelectedSite()
        try TabNavComponent()
            .goToMeScreen()
            .logoutToPrologue()
            .assertScreenIsLoaded()
    }

    /**
     This test opens safari to trigger the mocked magic link redirect
     */
    func testEmailMagicLinkLogin() throws {
        try WelcomeScreen()
            .selectLogin()
            .selectEmailLogin()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithLink()
            .openMagicLoginLink()
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
        try TabNavComponent()
            .goToMeScreen()
            .logout()
            .assertScreenIsLoaded()
    }

    // Unified self hosted login/out
    func testSelfHostedLoginLogout() throws {
        try PrologueScreen()
            .selectSiteAddress()
            .proceedWith(siteAddress: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWithSelfHosted(
                username: WPUITestCredentials.selfHostedUsername,
                password: WPUITestCredentials.selfHostedPassword
            )
            .removeSelfHostedSite()
        try PrologueScreen()
            .assertScreenIsLoaded()
    }

    // Unified WordPress.com email login failure due to incorrect password
    func testWPcomInvalidPassword() throws {
        try PrologueScreen()
            .selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithInvalidPassword()
            .verifyLoginError()
    }

    // Self-Hosted after WordPress.com login.
    // Login to a WordPress.com account, open site switcher, then add a self-hosted site.
    func testAddSelfHostedSiteAfterWPcomLogin() throws {
        try PrologueScreen()
            .selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithValidPassword()
            .verifyEpilogueDisplays(
                username: WPUITestCredentials.testWPcomUsername,
                siteUrl: WPUITestCredentials.testWPcomPaidSite
            )
            .continueWithSelectedSite() //returns MySite screen

            // From here, bring up the sites list and choose to add a new self-hosted site.
            .showSiteSwitcher()
            .addSelfHostedSite()

            // Then, go through the self-hosted login flow:
            .proceedWith(siteAddress: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWithSelfHostedSiteAddedFromSitesList(
                username: WPUITestCredentials.selfHostedUsername,
                password: WPUITestCredentials.selfHostedPassword
            )

            // Login flow returns MySites modal, which needs to be closed.
            .closeModal()
            .assertScreenIsLoaded()
            .removeSelfHostedSite()
    }
}
