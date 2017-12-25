import Foundation

class LoginFlow {

    static func login(email: String, password: String) -> MySitesScreen {
        logoutIfNeeded()

        return WelcomeScreen.init().login()
            .proceedWith(email: email)
            .proceedWithPassword()
            .proceedWith(password: password)
            .continueWithSelectedSite()
    }

    static func logoutIfNeeded() {
        if WelcomeScreen.isLoaded() ||
            LoginPasswordScreen.isLoaded() ||
            LoginEmailScreen.isLoaded() {

            return

        }
        Logger.log(message: "Logging out...", event: .i)

        _ = MySitesScreen.init().tabBar.gotoMeScreen().logout()
    }
}
