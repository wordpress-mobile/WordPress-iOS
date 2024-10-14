import UITestsFoundation
import XCTest

class LoginTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()
    }

    // Unified email login/out
    func testWPcomLoginLogout() throws {
        try PrologueScreen()
            .selectContinue()
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithValidPassword()
        try makeMainNavigationComponent()
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

        try makeMainNavigationComponent()
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
        if XCTestCase.isPad {
            try SidebarNavComponent()
                .openSiteMenu()
                .removeSelfHostedSite()
        } else {
            try MySiteScreen()
                .removeSelfHostedSite()
        }
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

            // From here, bring up the sites list and choose to add a new self-hosted site.
            .showSiteSwitcher()
            .addSelfHostedSite()

            // Then, go through the self-hosted login flow:
            .proceedWith(siteAddress: WPUITestCredentials.selfHostedSiteAddress)
            .proceedWithSelfHosted(
                username: WPUITestCredentials.selfHostedUsername,
                password: WPUITestCredentials.selfHostedPassword
            )

        if XCTestCase.isPad {
            try SidebarNavComponent()
                .openSiteMenu()
                .removeSelfHostedSite()
        } else {
            // Login flow returns MySites modal, which needs to be closed.
            try MySitesScreen()
                .closeModal()
                .assertScreenIsLoaded()
                .removeSelfHostedSite()
        }
    }
}
