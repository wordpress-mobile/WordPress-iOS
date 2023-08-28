import UITestsFoundation
import XCTest

class LanguageTests: XCTestCase {
    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    @MainActor
    func testGutenbergEditorTranslations() throws {
        setUpTestSuite()

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)

        setUpTestSuite(removeBeforeLaunching: false, logoutAtLaunch: false, testLanguage: "es")

        // Navigate to the block editor screen
        try TabNavComponent()
            .goToBlockEditorScreen()

        try BlockEditorScreen()
            .showsPostTitlePlaceholderInSpanish()
            .showsAddBlockPlaceholderInSpanish()
    }

}
