import ScreenObject
import UIKit
import UITestsFoundation
import XCTest

class JetpackScreenshotGeneration: XCTestCase {
    let scanWaitTime: UInt32 = 5

    override func setUpWithError() throws {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // This does the shared setup including injecting mocks and launching the app
        setUpTestSuite()

        // The app is already launched so we can set it up for screenshots here
        let app = XCUIApplication()
        setupSnapshot(app)

        if XCUIDevice.isPad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }

        try LoginFlow.login(email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGenerateScreenshots() throws {

        // Get My Site screenshot
        let mySite = try MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "yourjetpack.blog")
            .thenTakeScreenshot(1, named: "MySite")

        // Get Activity Log screenshot
        let activityLog = try mySite
            .goToActivityLog()
            .thenTakeScreenshot(2, named: "ActivityLog")

        if !XCUIDevice.isPad {
            activityLog.pop()
        }

        // Get Scan screenshot
        let jetpackScan = try mySite
            .goToJetpackScan()

        sleep(scanWaitTime)

        jetpackScan
            .thenTakeScreenshot(3, named: "JetpackScan")

        if !XCUIDevice.isPad {
            jetpackScan.pop()
        }

        // Get Backup screenshot
        let jetpackBackup = try mySite
            .goToJetpackBackup()

        let jetpackBackupOptions = try jetpackBackup
            .goToBackupOptions()
            .thenTakeScreenshot(4, named: "JetpackBackup")

        jetpackBackupOptions.pop()

        if !XCUIDevice.isPad {
            jetpackBackup.pop()
        }

        // Get Stats screenshot
        let statsScreen = try mySite.goToStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: .months)
            .thenTakeScreenshot(5, named: "Stats")
    }
}

extension BaseScreen {
    @discardableResult
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}

extension ScreenObject {

    @discardableResult
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
