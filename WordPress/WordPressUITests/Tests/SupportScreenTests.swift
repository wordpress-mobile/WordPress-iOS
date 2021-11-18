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

    func testContactUsCanBeLoadedDuringLogin() throws {
        let contactUsScreen = try PrologueScreen()
            .selectContinue()
            .selectHelp()
            .contactSupport()

        XCTAssert(contactUsScreen.isLoaded)

        //Dismiss because tearDown() can't handle modals currently
        try contactUsScreen.dismiss().dismiss()
        //This extra step is actually handled by tearDown(), but adding it here cuts the execution time in half
        try GetStartedScreen().goBackToPrologue()
    }
}
