import UITestsFoundation
import XCTest

final class AppSettingsTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite(removeBeforeLaunching: true)

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    func testImageOptimizationEnabledByDefault() throws {
        try TabNavComponent().goToMeScreen().goToAppSettings().verifyImageOptimizationSwitch(enabled: true)
    }

    func testImageOptimizationIsTurnedOnEditor() throws {
        try TabNavComponent().goToBlockEditorScreen().addImage().chooseOptimizeImages(option: true).closeEditor()
        try TabNavComponent().goToMeScreen().goToAppSettings().verifyImageOptimizationSwitch(enabled: true)
    }

    func testImageOptimizationIsTurnedOffEditor() throws {
        try TabNavComponent().goToBlockEditorScreen().addImage().chooseOptimizeImages(option: false).closeEditor()
        try TabNavComponent().goToMeScreen().goToAppSettings().verifyImageOptimizationSwitch(enabled: false)
    }
}
