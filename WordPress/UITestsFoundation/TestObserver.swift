import XCTest

class TestObserver: NSObject, XCTestObservation {
    override init() {
            super.init()
            XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testBundleWillStart(_ testBundle: Bundle) {
        // Code added here will run only once before all the tests
        executeWithRetries(disableAutoFillPasswords)
    }

    func testBundleDidFinish(_ testBundle: Bundle) {
        XCTestObservationCenter.shared.removeTestObserver(self)
    }

    func executeWithRetries(_ operation: () -> Bool) {
        var retryCount = 3

        while !operation() && retryCount > 0 {
            retryCount -= 1
        }
    }

    func disableAutoFillPasswords() -> Bool {
        return true

//        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
//        // Terminating Settings in case of a retry.
//        settings.terminate()
//        settings.activate()
//
//        let passwordsMenuItem = settings.staticTexts["Passwords"]
//        guard passwordsMenuItem.waitForIsHittable() else { return false }
//        passwordsMenuItem.tap()
//
//        let enterPasscodeScreen = XCUIApplication(bundleIdentifier: "com.apple.springboard")
//        let passwordField = enterPasscodeScreen.secureTextFields["Passcode field"]
//        guard passwordField.waitForIsHittable() else { return false }
//        passwordField.typeText(" \r")
//
//        let passwordOptions = settings.staticTexts["Password Options"]
//        guard passwordOptions.waitForIsHittable() else { return false }
//        passwordOptions.tap()
//
//        let autoFillPasswordsSwitch = settings.switches["AutoFill Passwords"]
//        guard autoFillPasswordsSwitch.waitForIsHittable() else { return false }
//
//        if autoFillPasswordsSwitch.value as? String == "1" {
//            autoFillPasswordsSwitch.tap()
//        }
//
//        settings.terminate()
//        return true
    }
}
