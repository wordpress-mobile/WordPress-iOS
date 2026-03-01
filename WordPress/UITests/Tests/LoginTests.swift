import UITestsFoundation
import XCTest

@MainActor
class LoginTests: XCTestCase {

    func testSelfHostedLoginLogout() throws {
        setUpTestSuite(arguments: [
            "-ui-test-site-url", WPUITestCredentials.selfHostedSiteAddress,
            "-ui-test-site-user", WPUITestCredentials.selfHostedUsername,
            "-ui-test-site-pass", WPUITestCredentials.selfHostedAppPassword
        ])
        try PrologueScreen()
            .selectSiteAddress()
            .proceedWithSelfHostedSiteLogin(
                siteAddress: WPUITestCredentials.selfHostedSiteAddress
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
}
