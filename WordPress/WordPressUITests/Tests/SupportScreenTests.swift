import UITestsFoundation
import XCTest

class SupportScreenTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        removeApp()
    }

    func testContactUsCanBeLoadedDuringLogin() throws {
        try PrologueScreen()
            .selectContinue()
            .selectHelp()
            .assertVisitForumButtonEnabled()
            .visitForums()
    }
}
