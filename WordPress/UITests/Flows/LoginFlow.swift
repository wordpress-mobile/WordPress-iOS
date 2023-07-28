import UITestsFoundation
import XCTest

class LoginFlow {

    @discardableResult
    static func login(email: String, password: String, selectedSiteTitle: String? = nil) throws -> MySiteScreen {
        return try PrologueScreen()
            .selectContinue()
            .proceedWith(email: email)
            .proceedWithValidPassword()
            .continueWithSelectedSite(title: selectedSiteTitle)
    }

    // Login with self-hosted site via Site Address.
    @discardableResult
    static func login(siteUrl: String, username: String, password: String) throws -> MySiteScreen {
        return try PrologueScreen()
            .selectSiteAddress()
            .proceedWith(siteUrl: siteUrl)
            .proceedWith(username: username, password: password)
            .continueWithSelectedSite()
    }

    // Login with WP site via Site Address.
    @discardableResult
    static func login(siteUrl: String, email: String, password: String, selectedSiteTitle: String? = nil) throws -> MySiteScreen {
        return try PrologueScreen()
            .selectSiteAddress()
            .proceedWithWordPress(siteUrl: siteUrl)
            .proceedWith(email: email)
            .proceedWithValidPassword()
            .continueWithSelectedSite(title: selectedSiteTitle)
    }

    // Login without selecting site
    @discardableResult
    static func loginWithoutSelectingSite(email: String) throws -> LoginEpilogueScreen {
        return try PrologueScreen()
            .selectContinue()
            .proceedWith(email: email)
            .proceedWithValidPassword()
    }
}
