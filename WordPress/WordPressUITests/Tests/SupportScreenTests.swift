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

        //close SupportScreen modal before teartown
        supportScreen.closeButton.tap()
    }
}
