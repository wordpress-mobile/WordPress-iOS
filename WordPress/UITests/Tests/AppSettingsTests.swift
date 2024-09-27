import UITestsFoundation
import XCTest

final class AppSettingsTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
    }

    func testImageOptimizationEnabledByDefault() throws {
        try makeMainNavigationComponent()
            .goToMeScreen()
            .goToAppSettings()
            .verifyImageOptimizationSwitch(enabled: true)
    }
}
