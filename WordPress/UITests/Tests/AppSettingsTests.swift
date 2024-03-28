import UITestsFoundation
import XCTest

final class AppSettingsTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        takeScreenshotOfFailedTest()
    }

    func testImageOptimizationEnabledByDefault() throws {
        try TabNavComponent()
            .goToMeScreen()
            .goToAppSettings()
            .verifyImageOptimizationSwitch(enabled: true)
    }
}
