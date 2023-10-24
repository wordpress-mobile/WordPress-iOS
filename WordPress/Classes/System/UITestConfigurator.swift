import Foundation

struct UITestConfigurator {
    static func prepareApplicationForUITests(_ application: UIApplication) {
        disableAnimations(application)
        logoutAtLaunch()
    }

    /// This method will disable animations and speed-up keyboad input if command-line arguments includes "NoAnimations"
    /// It was designed to be used in UI test suites. To enable it just pass a launch argument into XCUIApplicaton:
    ///
    /// XCUIApplication().launchArguments = ["-no-animations"]
    ///
    private static func disableAnimations(_ application: UIApplication) {
        if CommandLine.arguments.contains("-no-animations") {
            UIView.setAnimationsEnabled(false)
            application.windows.first?.layer.speed = MAXFLOAT
            application.mainWindow?.layer.speed = MAXFLOAT
        }
    }

    private static func logoutAtLaunch() {
        if CommandLine.arguments.contains("-logout-at-launch") {
            AccountHelper.logOutDefaultWordPressComAccount()
        }
    }
}
