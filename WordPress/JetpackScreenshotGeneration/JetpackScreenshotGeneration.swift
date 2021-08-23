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

        if isIpad {
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

    func testGenerateScreenshots() {

        // Get My Site screenshot
        let mySite = MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "yourjetpack.blog")
            .thenTakeScreenshot(1, named: "MySite")

        // Get Activity Log screenshot
        let activityLog = mySite
            .gotoActivityLog()
            .thenTakeScreenshot(2, named: "ActivityLog")

        if !isIpad {
            activityLog.pop()
        }

        // Get Scan screenshot
        let jetpackScan = mySite
            .gotoJetpackScan()

        sleep(scanWaitTime)

        jetpackScan
            .thenTakeScreenshot(3, named: "JetpackScan")

        if !isIpad {
            jetpackScan.pop()
        }

        // Get Backup screenshot
        let jetpackBackup = mySite
            .gotoJetpackBackup()

        let jetpackBackupOptions = jetpackBackup
            .goToBackupOptions()
            .thenTakeScreenshot(4, named: "JetpackBackup")

        jetpackBackupOptions.pop()

        if !isIpad {
            jetpackBackup.pop()
        }

        // Get Stats screenshot
        let statsScreen = mySite.gotoStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: .months)
            .thenTakeScreenshot(5, named: "Stats")
    }
}

extension BaseScreen {
    @discardableResult
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = isDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
