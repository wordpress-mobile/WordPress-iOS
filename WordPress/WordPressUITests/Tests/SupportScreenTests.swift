import UITestsFoundation
import XCTest

class SupportScreenTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite()
        try LoginFlow.logoutIfNeeded()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try ContactUsScreen().dismiss().dismiss()
        try GetStartedScreen().goBackToPrologue()
        try LoginFlow.logoutIfNeeded()
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
