import Foundation
@testable import WordPress


// MARK: - LoginFields Validation Tests
//
class LoginFieldsValidationTests: XCTestCase {

    func testValidateFieldsPopulatedForSignin() {
        let loginFields = LoginFields()
        loginFields.meta.userIsDotCom = true

        XCTAssertFalse(loginFields.validateFieldsPopulatedForSignin(), "Empty fields should not validate.")

        loginFields.username = "user"
        XCTAssertFalse(loginFields.validateFieldsPopulatedForSignin(), "Should not validate with just a username")

        loginFields.password = "password"
        XCTAssert(loginFields.validateFieldsPopulatedForSignin(), "should validate wpcom with username and password.")

        loginFields.meta.userIsDotCom = false
        XCTAssertFalse(loginFields.validateFieldsPopulatedForSignin(), "should not validate self-hosted with just username and password.")

        loginFields.siteAddress = "example.com"
        XCTAssert(loginFields.validateFieldsPopulatedForSignin(), "should validate self-hosted with username, password, and site.")
    }

    func testValidateSiteForSignin() {
        let loginFields = LoginFields()

        loginFields.siteAddress = ""
        XCTAssertFalse(loginFields.validateSiteForSignin(), "Empty site should not validate.")

        loginFields.siteAddress = "hostname"
        XCTAssert(loginFields.validateSiteForSignin(), "Just a host name should validate.")

        loginFields.siteAddress = "host name.com"
        XCTAssertFalse(loginFields.validateSiteForSignin(), "Hostname with spaces should not validate.")
    }
}
