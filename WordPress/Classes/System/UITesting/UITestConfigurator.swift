import UIKit
import WordPressData
import JetpackStats

struct UITestConfigurator {
    static func isUITesting() -> Bool {
        CommandLine.arguments.contains("-ui-testing")
    }

    /// Applies the process-scoped part of the UI-test setup: flag parsing and, when
    /// requested, wiping persistent state. Must run at the very start of the launch
    /// sequence, before anything reads the flags or touches Core Data and user defaults.
    static func prepareApplicationForUITests() {
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
            UIView.setAnimationsEnabled(false)
        }
        if arguments.contains("-ui-test-use-mock-data") {
            flags.insert(.useMockData)
        }
        if arguments.contains("-ui-test-screenshot-generation") {
            flags.insert(.screenshotGeneration)
            ChartCardConfiguration.defaultChartType = .line
        }
        if arguments.contains("-ui-test-reset-everything") {
            resetEverything()
        }
    }

    /// Applies the window-scoped part of the UI-test setup. Runs whenever the main
    /// window is created, which (under the scene life cycle) happens at scene connect,
    /// after `prepareApplicationForUITests()` already parsed the flags.
    static func prepareWindowForUITests(_ window: UIWindow) {
        if isEnabled(.disableAnimations) {
            window.layer.speed = MAXFLOAT
        }
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

    /// Use programatically created mock data where possible.
    static let useMockData = UITestFlag(rawValue: 1 << 5)

    /// If enabled, the screenshot generation is running.
    static let screenshotGeneration = UITestFlag(rawValue: 1 << 6)
}
