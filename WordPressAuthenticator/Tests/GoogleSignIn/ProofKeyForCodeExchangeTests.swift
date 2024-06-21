@testable import WordPressAuthenticator
import XCTest

class ProofKeyForCodeExchangeTests: XCTestCase {

    func testCodeChallengeInPlainModeIsTheSameAsCodeVerifier() throws {
        let codeVerifier = ProofKeyForCodeExchange.CodeVerifier.fixture()

        XCTAssertEqual(
            ProofKeyForCodeExchange(codeVerifier: codeVerifier, method: .plain).codeChallenge,
            codeVerifier.rawValue
        )
    }

    func testCodeChallengeInS256ModeIsEncodedAsPerSpec() {
        let codeVerifier = ProofKeyForCodeExchange.CodeVerifier(value: (0..<9).map { _ in "test-" }.joined())!

        XCTAssertEqual(
            ProofKeyForCodeExchange(codeVerifier: codeVerifier, method: .s256).codeChallenge,
            "lWvomVEGuL8FR3DY2DP_9E2q_imlqUHi-s1SPqRhO2c"
        )
    }

    func testMethodURLQueryParameterValuePlain() {
        XCTAssertEqual(ProofKeyForCodeExchange.Method.plain.urlQueryParameterValue, "plain")
    }

    func testMethodURLQueryParameterValueS256() {
        XCTAssertEqual(ProofKeyForCodeExchange.Method.s256.urlQueryParameterValue, "S256")
    }
}
