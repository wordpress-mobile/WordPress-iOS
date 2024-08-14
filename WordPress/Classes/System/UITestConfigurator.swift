import Foundation

struct UITestConfigurator {
    static func prepareApplicationForUITests(_ application: UIApplication) {
        disableAnimations(application)
        logoutAtLaunch()
        disableCompliancePopover()
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
            removeSelfHostedSites()
            AccountHelper.logOutDefaultWordPressComAccount()
        }
    }

    private static func removeSelfHostedSites() {
        let context = ContextManager.shared.mainContext
        let service = BlogService(coreDataStack: ContextManager.shared)
        let blogs = try? BlogQuery().hostedByWPCom(false).blogs(in: context)
        for blog in blogs ?? [] {
            service.remove(blog)
        }
    }

    private static func disableCompliancePopover() {
        if CommandLine.arguments.contains("-ui-testing") {
            UserDefaults.standard.didShowCompliancePopup = true
            UserPersistentStoreFactory.instance().onboardingNotificationsPromptDisplayed = true
        }
    }
}
