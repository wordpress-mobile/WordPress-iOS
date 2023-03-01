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

    func testSupportForumsCanBeLoadedDuringLogin() throws {
        try PrologueScreen()
            .selectContinue()
            .selectHelp()
            .assertVisitForumButtonEnabled()
            .visitForums()
            .assertForumsLoaded()
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
