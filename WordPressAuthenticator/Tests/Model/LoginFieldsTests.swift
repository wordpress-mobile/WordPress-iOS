@testable import WordPressAuthenticator
import XCTest

class LoginFieldsTests: XCTestCase {

    func testSignInWithAppleParametersNilWhenNoSocialUser() {
        XCTAssertNil(LoginFields().parametersForSignInWithApple)
    }

    func testSignInWithAppleParametersNilWhenSocialUserNotApple() {
        let fields = LoginFields()
        fields.meta = LoginFieldsMeta(
            socialUser: SocialUser(email: "email", fullName: "name", service: .google)
        )

        XCTAssertNil(fields.parametersForSignInWithApple)
    }

    func testSignInWithAppleParametersHasEmailAndNameWhenSocialUserIsApple() throws {
        let fields = LoginFields()
        fields.meta = LoginFieldsMeta(
            socialUser: SocialUser(email: "email", fullName: "name", service: .apple)
        )

        let parameters = try XCTUnwrap(fields.parametersForSignInWithApple)
        XCTAssertEqual(parameters["user_email"] as? String, "email")
        XCTAssertEqual(parameters["user_name"] as? String, "name")
    }
}
