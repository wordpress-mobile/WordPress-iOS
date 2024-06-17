@testable import WordPressAuthenticator
import XCTest

class IDTokenTests: XCTestCase {

    func testInitWithJWTWithoutNameNorEmailFails() throws {
        XCTAssertNil(IDToken(jwt: try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTString))))
    }

    func testInitWithJWTWithoutEmailFails() throws {
        XCTAssertNil(IDToken(jwt: try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTStringWithNameOnly))))
    }

    func testInitWithJWTWithoutNameFails() throws {
        XCTAssertNil(IDToken(jwt: try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTStringWithEmailOnly))))
    }

    func testInitWithJWTWithNameAndEmailSucceeds() throws {
        let jwt = try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTStringWithNameAndEmail))
        let token = try XCTUnwrap(IDToken(jwt: jwt))

        XCTAssertEqual(token.name, JSONWebToken.nameFromValidJWTStringWithEmail)
        XCTAssertEqual(token.email, JSONWebToken.emailFromValidJWTStringWithEmail)
    }

}
