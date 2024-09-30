@testable import WordPressAuthenticator
import XCTest

class JWTokenTests: XCTestCase {

    func testJWTokenDecodingFromInvalidStringFails() {
        XCTAssertNil(JSONWebToken(encodedString: "invalid"))
    }

    func testJWTokenDecodingWithoutHeaderFails() {
        let inputWithoutHeader = JSONWebToken.validJWTString.split(separator: ".").dropFirst().joined(separator: ".")
        XCTAssertNil(JSONWebToken(encodedString: inputWithoutHeader))
    }

    func testJWTokenDecodingFromValidString() throws {
        let token = try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTString))

        XCTAssertEqual(
            token.header as? [String: String],
            ["alg": "HS256", "typ": "JWT"]
        )

        XCTAssertEqual(
            token.payload as? [String: String],
            ["key": "value", "other_key": "other_value"]
        )
    }
}
