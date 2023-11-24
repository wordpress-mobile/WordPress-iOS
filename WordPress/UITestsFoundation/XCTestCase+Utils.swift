import XCTest

public extension XCTestCase {

    func removeApp(_ app: XCUIApplication = XCUIApplication()) {
        // We need to store the app name before calling `terminate()` if we want to delete it.
        // Otherwise, we won't be able to access it to read its name as the test will fail with:
        //
        // > Failed to get matching snapshot: Application org.wordpress is not running
        //
        // Launch the app to access its name so we can deleted it from Springboard
        switch app.state {
        case .unknown, .notRunning:
            app.launch()
        default:
            break
        }

        let appName = app.label
        app.terminate()

        let appToRemove = Apps.springboard.icons[appName]

        guard appToRemove.exists else {
            return
        }

        appToRemove.firstMatch.press(forDuration: 1)
        waitAndTap(Apps.springboard.buttons["Remove App"])
        waitForExistenceAndTap(Apps.springboard.alerts.buttons["Delete App"])
        waitAndTap(Apps.springboard.alerts.buttons["Delete"])
    }

}
