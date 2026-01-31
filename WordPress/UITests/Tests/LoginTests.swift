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
}
