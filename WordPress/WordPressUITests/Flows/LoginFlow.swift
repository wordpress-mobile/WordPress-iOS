import XCTest

class LoginFlow {

    static func login(email: String, password: String) -> MySiteScreen {
        logoutIfNeeded()

        return WelcomeScreen().login()
            .proceedWith(email: email)
            .proceedWithPassword()
            .proceedWith(password: password)
            .continueWithSelectedSite()
    }

    static func logoutIfNeeded() {
        if TabNavComponent.isLoaded() {
            Logger.log(message: "Logging out...", event: .i)
            _ = TabNavComponent().gotoMeScreen().logout()
            return
        }

        while LoginPasswordScreen.isLoaded() || LoginEmailScreen.isLoaded() || LinkOrPasswordScreen.isLoaded() {
            XCUIApplication().buttons["Back"].tap()
        }
    }
}
