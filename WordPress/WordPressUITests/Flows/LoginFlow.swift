import XCTest

class LoginFlow {

    static func login(email: String, password: String) -> MySiteScreen {
        logoutIfNeeded()

        return WelcomeScreen().login()
            .proceedWith(email: email)
            .proceedWithPassword()
            .proceedWith(password: password)
            .continueWithSelectedSite()
            .dismissNotificationAlertIfNeeded()
    }

    static func loginIfNeeded(email: String, password: String) -> TabNavComponent {
        guard TabNavComponent.isLoaded() else {
            return login(email: email, password: password).tabBar
        }
        return TabNavComponent()
    }

    static func logoutIfNeeded() {
        if TabNavComponent.isLoaded() {
            Logger.log(message: "Logging out...", event: .i)
            let meScreen = TabNavComponent().gotoMeScreen()
            if meScreen.isLoggedInToWpcom() {
                _ = meScreen.logout()
            } else {
                _ = TabNavComponent().gotoMySiteScreen()
                .removeSelfHostedSite()
            }
            return
        }

        while LoginPasswordScreen.isLoaded() || LoginEmailScreen.isLoaded() || LinkOrPasswordScreen.isLoaded() || LoginSiteAddressScreen.isLoaded() || LoginUsernamePasswordScreen.isLoaded() || LoginCheckMagicLinkScreen.isLoaded() {
            if LoginEmailScreen.isLoaded() && LoginEmailScreen.isEmailEntered() {
                LoginEmailScreen().emailTextField.clearTextIfNeeded()
            }
            XCUIApplication().buttons["Back"].tap()
        }
    }
}
