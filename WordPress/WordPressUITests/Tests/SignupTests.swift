import UITestsFoundation
import XCTest

class SignupTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow.logoutIfNeeded()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    func testEmailSignup() throws {
        let mySiteScreen = try WelcomeScreen().selectSignup()
            .selectEmailSignup()
            .proceedWith(email: WPUITestCredentials.signupEmail)
            .openMagicSignupLink()
            .verifyEpilogueContains(username: WPUITestCredentials.signupUsername, displayName: WPUITestCredentials.signupDisplayName)
            .setPassword(WPUITestCredentials.signupPassword)
            .continueWithSignup()
            .dismissNotificationAlertIfNeeded()

        XCTAssert(mySiteScreen.isLoaded)
    }
}
