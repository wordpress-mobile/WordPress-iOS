import XCTest

class SignupTests: XCTestCase {

    override func setUp() {
        setUpTestSuite()

        LoginFlow.logoutIfNeeded()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testEmailSignup() {
        let mySiteScreen = WelcomeScreen().selectSignup()
            .selectEmailSignup()
            .proceedWith(email: WPUITestCredentials.signupEmail)
            .openMagicSignupLink()
            .verifyEpilogueContains(username: WPUITestCredentials.signupUsername, displayName: WPUITestCredentials.signupDisplayName)
            .setPassword(WPUITestCredentials.signupPassword)
            .continueWithSignup()
            .dismissNotificationAlertIfNeeded()

        XCTAssert(mySiteScreen.isLoaded())
    }

    // Test Support Section Loads
    // From Prologue > continue, tap "help" and make sure Support Screen loads
    func testSupportScreenLoads() {
        let supportScreen = PrologueScreen().selectContinue().selectHelp()

        XCTAssert(supportScreen.isLoaded())
        SupportScreen().closeButton.tap()
    }
}
