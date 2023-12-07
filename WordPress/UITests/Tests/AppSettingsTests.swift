import UITestsFoundation
import XCTest

final class AppSettingsTests: XCTestCase {

    let testsRequiringAppDeletion = [
        "testImageOptimizationEnabledByDefault",
        "testImageOptimizationIsTurnedOnEditor",
        "testImageOptimizationIsTurnedOffEditor"
    ]

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()

        let removeBeforeLaunching = testsRequiringAppDeletion.contains { testName in
            self.name.contains(testName)
        }
        setUpTestSuite(removeBeforeLaunching: removeBeforeLaunching)

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)
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

    func testImageOptimizationIsTurnedOnEditor() throws {
        try TabNavComponent()
            .goToBlockEditorScreen()
            .addImage()
            .chooseOptimizeImages(option: true)
            .closeEditor()
        try TabNavComponent()
            .goToMeScreen()
            .goToAppSettings()
            .verifyImageOptimizationSwitch(enabled: true)
    }

    func testImageOptimizationIsTurnedOffEditor() throws {
        try TabNavComponent()
            .goToBlockEditorScreen()
            .addImage()
            .chooseOptimizeImages(option: false)
            .closeEditor()
        try TabNavComponent()
            .goToMeScreen()
            .goToAppSettings()
            .verifyImageOptimizationSwitch(enabled: false)
    }
}
