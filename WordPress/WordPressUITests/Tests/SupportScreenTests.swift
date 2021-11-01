import UITestsFoundation
import XCTest

class SupportScreenTests: XCTestCase {

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.logoutIfNeeded()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    // Test Support Section Loads
    // From Prologue > continue, tap "help" and make sure Support Screen loads
    func testSupportScreenLoads() throws {
        let supportScreen = try PrologueScreen().selectContinue().selectHelp()

        XCTAssert(supportScreen.isLoaded)

        //Dismiss because tearDown() can't handle modals currently
        supportScreen.dismiss()
    }
}
