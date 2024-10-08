import UITestsFoundation
import XCTest

class SignupTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()
    }

    func testEmailSignup() throws {
        try WelcomeScreen()
            .selectSignup()
            .selectEmailSignup()
            .proceedWith(email: WPUITestCredentials.signupEmail)
            .openMagicSignupLink()
            .verifyEpilogueContains(
                username: WPUITestCredentials.signupUsername,
                displayName: WPUITestCredentials.signupDisplayName
            )
            .setPassword(WPUITestCredentials.signupPassword)
            .continueWithSignup()
            .assertScreenIsLoaded()
    }
}
