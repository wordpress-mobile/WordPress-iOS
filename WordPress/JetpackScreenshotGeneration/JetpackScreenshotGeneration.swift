import UIKit
import XCTest

class JetpackScreenshotGeneration: XCTestCase {
    let imagesWaitTime: UInt32 = 10

    override func setUp() {
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

        LoginFlow.login(siteUrl: "WordPress.com", username: ScreenshotCredentials.username, password: ScreenshotCredentials.password)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGenerateScreenshots() {

        // Get My Site screenshot
        let mySite = MySiteScreen()
            .thenTakeScreenshot(1, named: "MySite")

        // Get Activity Log screenshot
        // TODO

        // Get Scan screenshot
        // TODO

        // Get Backup screenshot
        // TODO

        // Get Stats screenshot
        let statsScreen = mySite.gotoStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: .months)
            .thenTakeScreenshot(5, named: "Stats")
    }
}
