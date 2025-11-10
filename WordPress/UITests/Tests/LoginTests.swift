import UITestsFoundation
import XCTest

@MainActor
class LoginTests: XCTestCase {

    // Unified self hosted login/out
    func testSelfHostedLoginLogout() throws {
        setUpTestSuite()
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

    // Self-Hosted after WordPress.com login.
    // Login to a WordPress.com account, open site switcher, then add a self-hosted site.
    func testAddSelfHostedSiteAfterWPcomLogin() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomFreeSite)

        // From here, bring up the sites list and choose to add a new self-hosted site.
        try MySiteScreen()
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
