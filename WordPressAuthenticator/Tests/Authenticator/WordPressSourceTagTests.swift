import XCTest
import WordPressAuthenticator

class WordPressSourceTagTests: XCTestCase {

    func testGeneralLoginSourceTag() {
        let tag = WordPressSupportSourceTag.generalLogin

        XCTAssertEqual(tag.name, "generalLogin")
        XCTAssertEqual(tag.origin, "origin:login-screen")
    }

    func testJetpackLoginSourceTag() {
        let tag = WordPressSupportSourceTag.jetpackLogin

        XCTAssertEqual(tag.name, "jetpackLogin")
        XCTAssertEqual(tag.origin, "origin:jetpack-login-screen")
    }

    func testLoginEmailSourceTag() {
        let tag = WordPressSupportSourceTag.loginEmail

        XCTAssertEqual(tag.name, "loginEmail")
        XCTAssertEqual(tag.origin, "origin:login-email")
    }

    func testLoginAppleSourceTag() {
        let tag = WordPressSupportSourceTag.loginApple

        XCTAssertEqual(tag.name, "loginApple")
        XCTAssertEqual(tag.origin, "origin:login-apple")
    }

    func testlogin2FASourceTag() {
        let tag = WordPressSupportSourceTag.login2FA

        XCTAssertEqual(tag.name, "login2FA")
        XCTAssertEqual(tag.origin, "origin:login-2fa")
    }

    func testLoginMagicLinkSourceTag() {
        let tag = WordPressSupportSourceTag.loginMagicLink

        XCTAssertEqual(tag.name, "loginMagicLink")
        XCTAssertEqual(tag.origin, "origin:login-magic-link")
    }

    func testSiteAddressSourceTag() {
        let tag = WordPressSupportSourceTag.loginSiteAddress

        XCTAssertEqual(tag.name, "loginSiteAddress")
        XCTAssertEqual(tag.origin, "origin:login-site-address")
    }

    func testVerifyEmailInstructionsSourceTag() {
        let tag = WordPressSupportSourceTag.verifyEmailInstructions

        XCTAssertEqual(tag.name, "verifyEmailInstructions")
        XCTAssertEqual(tag.origin, "origin:login-site-address")
    }

    func testLoginUsernameSourceTag() {
        let tag = WordPressSupportSourceTag.loginUsernamePassword

        XCTAssertEqual(tag.name, "loginUsernamePassword")
        XCTAssertEqual(tag.origin, "origin:login-username-password")
    }

    func testLoginUsernamePasswordSourceTag() {
        let tag = WordPressSupportSourceTag.loginWPComUsernamePassword

        XCTAssertEqual(tag.name, "loginWPComUsernamePassword")
        XCTAssertEqual(tag.origin, "origin:wpcom-login-username-password")
    }

    func testLoginWPComPasswordSourceTag() {
        let tag = WordPressSupportSourceTag.loginWPComPassword

        XCTAssertEqual(tag.name, "loginWPComPassword")
        XCTAssertEqual(tag.origin, "origin:login-wpcom-password")
    }

    func testWPComSignupEmailSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupEmail

        XCTAssertEqual(tag.name, "wpComSignupEmail")
        XCTAssertEqual(tag.origin, "origin:wpcom-signup-email-entry")
    }

    func testWPComSignupSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignup

        XCTAssertEqual(tag.name, "wpComSignup")
        XCTAssertEqual(tag.origin, "origin:signup-screen")
    }

    func testWPComSignupWaitingForGoogleSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupWaitingForGoogle

        XCTAssertEqual(tag.name, "wpComSignupWaitingForGoogle")
        XCTAssertEqual(tag.origin, "origin:signup-waiting-for-google")
    }

    func testWPComAuthGoogleSignupWaitingForGoogleSourceTag() {
        let tag = WordPressSupportSourceTag.wpComAuthWaitingForGoogle

        XCTAssertEqual(tag.name, "wpComAuthWaitingForGoogle")
        XCTAssertEqual(tag.origin, "origin:auth-waiting-for-google")
    }

    func testWPComAuthGoogleSignupConfirmationSourceTag() {
        let tag = WordPressSupportSourceTag.wpComAuthGoogleSignupConfirmation

        XCTAssertEqual(tag.name, "wpComAuthGoogleSignupConfirmation")
        XCTAssertEqual(tag.origin, "origin:auth-google-signup-confirmation")
    }

    func testWPComSignupMagicLinkSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupMagicLink

        XCTAssertEqual(tag.name, "wpComSignupMagicLink")
        XCTAssertEqual(tag.origin, "origin:signup-magic-link")
    }

    func testWPComSignupAppleSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupApple

        XCTAssertEqual(tag.name, "wpComSignupApple")
        XCTAssertEqual(tag.origin, "origin:signup-apple")
    }
}
