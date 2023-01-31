import UITestsFoundation
import XCTest

class SupportScreenTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite(for: "Jetpack")
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        removeApp("Jetpack")
    }

    func testContactUsCanBeLoadedDuringLogin() throws {
        try PrologueScreen()
            .selectContinue()
            .selectHelp()
            .contactSupport()
            .assertCanNotSendEmptyMessage()
            .enterText("A")
            .assertCanSendMessage()
    }
}
