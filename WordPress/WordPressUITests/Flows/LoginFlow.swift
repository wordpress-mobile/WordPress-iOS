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

    static func logoutIfNeeded() {
        if TabNavComponent.isLoaded() {
            Logger.log(message: "Logging out...", event: .i)
            let meScreen = TabNavComponent().gotoMeScreen()
            if meScreen.isLoggedInToWpcom() {
                _ = meScreen.logout()
            } else {
                _ = TabNavComponent().gotoMySitesScreen()
                .removeSelfHostedSite()
            }
            return
        }

        while LoginPasswordScreen.isLoaded() || LoginEmailScreen.isLoaded() || LinkOrPasswordScreen.isLoaded() || LoginSiteAddressScreen.isLoaded() || LoginUsernamePasswordScreen.isLoaded() {
            if LoginEmailScreen.isLoaded() && LoginEmailScreen.isEmailEntered() {
                LoginEmailScreen().emailTextField.clearAndEnterText(text: "")
            }
            XCUIApplication().buttons["Back"].tap()
        }
    }
}
