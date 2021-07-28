import XCTest

class SupportScreenTests: XCTestCase {

    override func setUp() {
        setUpTestSuite()

        LoginFlow.logoutIfNeeded()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    // Test Support Section Loads
    // From Prologue > continue, tap "help" and make sure Support Screen loads
    func testSupportScreenLoads() {
        let supportScreen = PrologueScreen().selectContinue().selectHelp()

        XCTAssert(supportScreen.isLoaded())

        //Dismiss because tearDown() can't handle modals currently
        supportScreen.dismiss()
    }
}
