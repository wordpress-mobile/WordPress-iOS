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

    func executeWithRetries(_ operation: () -> Bool) {
        var retryCount = 3

        while !operation() && retryCount > 0 {
            retryCount -= 1
        }
    }

    func disableAutoFillPasswords() -> Bool {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.terminate()

        settings.activate()
        let passwordsMenuItem = settings.staticTexts["Passwords"]
        passwordsMenuItem.waitForIsHittable()
        guard passwordsMenuItem.waitForIsHittable() else {
            XCTFail("SetUp Failed: Passwords menu item was not hittable in Settings.")
            return false
        }
        settings.staticTexts["Passwords"].tap()

        let enterPasscodeScreen = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passwordField = enterPasscodeScreen.secureTextFields["Passcode field"]
        guard passwordField.waitForIsHittable() else {
            XCTFail("SetUp Failed: Password field was not hittable in 'Enter passcode screen.")
            return false
        }
        passwordField.typeText(" \r")

        let passwordOptions = settings.staticTexts["Password Options"]
        guard passwordOptions.waitForIsHittable() else {
            XCTFail("SetUp Failed: Password Options was not hittable in Passwords.")
            return false
        }
        passwordOptions.tap()

        let autoFillPasswordsSwitch = settings.switches["AutoFill Passwords"]
        guard autoFillPasswordsSwitch.waitForIsHittable() else {
            XCTFail("SetUp Failed: AutoFill Passwords switch was not hittable in Passwords Options.")
            return false
        }

        if autoFillPasswordsSwitch.value as? String == "1" {
            autoFillPasswordsSwitch.tap()
        }

        settings.terminate()
        return true
    }
}
