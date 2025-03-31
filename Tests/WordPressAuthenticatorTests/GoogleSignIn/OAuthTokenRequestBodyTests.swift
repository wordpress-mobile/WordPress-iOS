@testable import WordPressAuthenticator
import XCTest

class OAuthTokenRequestBodyTests: XCTestCase {

    func testURLEncodedDataConversion() throws {
        let codeVerifier = ProofKeyForCodeExchange.CodeVerifier.fixture()
        let body = OAuthTokenRequestBody(
            clientId: "clientId",
            clientSecret: "clientSecret",
            audience: "audience",
            code: "codeValue",
            codeVerifier: codeVerifier,
            grantType: "grantType",
            redirectURI: "redirectUri"
        )

        let data = try body.asURLEncodedData()

        let decodedData = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(decodedData.contains("client_id=clientId"))
        XCTAssertTrue(decodedData.contains("client_secret=clientSecret"))
        XCTAssertTrue(decodedData.contains("code_verifier=\(codeVerifier.rawValue)"))
        XCTAssertTrue(decodedData.contains("grant_type=grantType"))
        XCTAssertTrue(decodedData.contains("redirect_uri=redirectUri"))
    }
}
