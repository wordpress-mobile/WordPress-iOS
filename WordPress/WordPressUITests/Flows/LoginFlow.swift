import UITestsFoundation
import XCTest

class LoginFlow {

    @discardableResult
    static func login(email: String, password: String) throws -> MySiteScreen {
        return try PrologueScreen().selectContinue()
            .proceedWith(email: email)
            .proceedWith(password: password)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
    }

    // Login with self-hosted site via Site Address.
    @discardableResult
    static func login(siteUrl: String, username: String, password: String) throws -> MySiteScreen {
        return try PrologueScreen().selectSiteAddress()
            .proceedWith(siteUrl: siteUrl)
            .proceedWith(username: username, password: password)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()

        // TODO: remove when unifiedAuth is permanent.
        // Leaving here for now in case unifiedAuth is disabled.
//        return WelcomeScreen().selectLogin()
//            .goToSiteAddressLogin()
//            .proceedWith(siteUrl: siteUrl)
//            .proceedWith(username: username, password: password)
//            .continueWithSelectedSite()
//            .dismissNotificationAlertIfNeeded()
    }

    // Login with WP site via Site Address.
    @discardableResult
    static func login(siteUrl: String, email: String, password: String) throws -> MySiteScreen {
        return try PrologueScreen().selectSiteAddress()
            .proceedWithWP(siteUrl: siteUrl)
            .proceedWith(email: email)
            .proceedWith(password: password)
        .continueWithSelectedSite()
        .dismissNotificationAlertIfNeeded()
    }

    // Login with self-hosted site via Site Address.
    static func loginIfNeeded(siteUrl: String, username: String, password: String) throws -> TabNavComponent {
        guard TabNavComponent.isLoaded() else {
            return try login(siteUrl: siteUrl, username: username, password: password).tabBar
        }
        return try TabNavComponent()
    }
}
