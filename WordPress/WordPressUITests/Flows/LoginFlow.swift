import UITestsFoundation
import XCTest

class LoginFlow {

    @discardableResult
    static func login(email: String, password: String) throws -> MySiteScreen {
        try logoutIfNeeded()

        return try PrologueScreen().selectContinue()
            .proceedWith(email: email)
            .proceedWith(password: password)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
    }

    // Login with self-hosted site via Site Address.
    @discardableResult
    static func login(siteUrl: String, username: String, password: String) throws -> MySiteScreen {
        try logoutIfNeeded()

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
        try logoutIfNeeded()

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

    // Login with WP site via Site Address.
    static func loginIfNeeded(siteUrl: String, email: String, password: String) throws -> TabNavComponent {
        guard TabNavComponent.isLoaded() else {
            return try login(siteUrl: siteUrl, email: email, password: password).tabBar
        }
        return try TabNavComponent()
    }

    static func logoutIfNeeded() throws {
        try XCTContext.runActivity(named: "Log out of app if currently logged in") { (activity) in
            if TabNavComponent.isLoaded() {
                Logger.log(message: "Logging out...", event: .i)
                let meScreen = try TabNavComponent().goToMeScreen()
                if meScreen.isLoggedInToWpcom() {
                    _ = try meScreen.logoutToPrologue()
                } else {
                    try meScreen.dismiss().removeSelfHostedSite()
                }
                return
            }
        }

        try XCTContext.runActivity(named: "Return to app prologue screen if needed") { (activity) in
            if !PrologueScreen.isLoaded() {
                while PasswordScreen.isLoaded() || GetStartedScreen.isLoaded() || LinkOrPasswordScreen.isLoaded() || LoginSiteAddressScreen.isLoaded() || LoginUsernamePasswordScreen.isLoaded() || LoginCheckMagicLinkScreen.isLoaded() {
                    if GetStartedScreen.isLoaded() && GetStartedScreen.isEmailEntered() {
                        try GetStartedScreen().emailTextField.clearText()
                    }
                    navBackButton.tap()
                }
            }

            // TODO: remove when unifiedAuth is permanent.
            // Leaving here for now in case unifiedAuth is disabled.
//            if !WelcomeScreen.isLoaded() {
//                while LoginPasswordScreen.isLoaded() || LoginEmailScreen.isLoaded() || LinkOrPasswordScreen.isLoaded() || LoginSiteAddressScreen.isLoaded() || LoginUsernamePasswordScreen.isLoaded() || LoginCheckMagicLinkScreen.isLoaded() {
//                    if LoginEmailScreen.isLoaded() && LoginEmailScreen.isEmailEntered() {
//                        LoginEmailScreen().emailTextField.clearTextIfNeeded()
//                    }
//                    navBackButton.tap()
//                }
//            }
        }
    }
}
