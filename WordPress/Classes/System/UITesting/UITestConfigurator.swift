import Foundation

struct UITestConfigurator {
    static func prepareApplicationForUITests(in app: UIApplication, window: UIWindow) {
        let arguments = CommandLine.arguments
        if arguments.contains("-ui-testing") {
            flags.insert(.disableLogging)
        }
        if arguments.contains("-ui-test-disable-prompts") {
            flags.insert(.disablePrompts)
        }
        if arguments.contains("-ui-test-disable-migration") {
            flags.insert(.disableMigration)
        }
        if arguments.contains("-ui-test-disable-autofill") {
            flags.insert(.disableAutofill)
        }
        if arguments.contains("-ui-test-disable-animations") {
            flags.insert(.disableAnimations)
            disableAnimations(in: app, window: window)
        }
        if arguments.contains("-ui-test-reset-everything") {
            resetEverything()
        }
    }

    /// This method will disable animations and speed-up keyboad input if command-line arguments includes "NoAnimations"
    /// It was designed to be used in UI test suites. To enable it just pass a launch argument into XCUIApplicaton.
    private static func disableAnimations(in app: UIApplication, window: UIWindow) {
        UIView.setAnimationsEnabled(false)
        window.layer.speed = MAXFLOAT
    }

    private static func resetEverything() {
        // Remove CoreData DB
        ContextManager.shared.resetEverything()

        // Clear user defaults.
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static var flags: UITestFlag = []

    static func isEnabled(_ flag: UITestFlag) -> Bool {
        flags.contains(flag)
    }
}

struct UITestFlag: OptionSet {
    let rawValue: UInt16

    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// Disable all active prompts in the app, such as "Allow Notifications"
    /// reminders, and others.
    static let disablePrompts = UITestFlag(rawValue: 1 << 0)

    /// Disable migration from the WordPress app to ensure that it doesn't
    /// interfere with UI tests on local devices when the app happens to be installed.
    static let disableMigration = UITestFlag(rawValue: 1 << 1)

    /// Disable password Autofill, preventing the automated prompts from appearing
    /// during the login to enter any already saved password and after the login
    /// to save a password.
    static let disableAutofill = UITestFlag(rawValue: 1 << 2)

    /// Disables all animations, including the ones not managed by `UIView`.
    static let disableAnimations = UITestFlag(rawValue: 1 << 3)

    static let disableLogging = UITestFlag(rawValue: 1 << 4)
}
