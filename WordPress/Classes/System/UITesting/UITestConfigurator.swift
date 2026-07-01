import Foundation
import WordPressData

struct UITestConfigurator {
    static func prepareApplicationForUITests() {
        if CommandLine.arguments.contains("-ui-test-reset-everything") {
            resetEverything()
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
}
