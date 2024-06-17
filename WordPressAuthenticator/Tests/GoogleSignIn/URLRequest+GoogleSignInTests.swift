@testable import WordPressAuthenticator
import XCTest

class URLRequestOAuthTokenRequestTests: XCTestCase {

    let testBody = OAuthTokenRequestBody(
        clientId: "a",
        clientSecret: "b",
        audience: "audience",
        code: "c",
        codeVerifier: ProofKeyForCodeExchange.CodeVerifier.fixture(),
        grantType: "e",
        redirectURI: "f"
    )

    func testURL() throws {
        let request = try URLRequest.googleSignInTokenRequest(body: testBody)
        XCTAssertEqual(request.url, URL(string: "https://oauth2.googleapis.com/token")!)
    }

    func testMethodPost() throws {
        let request = try URLRequest.googleSignInTokenRequest(body: testBody)
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testContentTypeFormURLEncoded() throws {
        let request = try URLRequest.googleSignInTokenRequest(body: testBody)
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded; charset=UTF-8"
        )
    }
}
