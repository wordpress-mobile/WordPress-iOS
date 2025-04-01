@testable import WordPressAuthenticator
import XCTest

class CodeVerifierTests: XCTestCase {

    func testCodeVerifierIsRandomString() throws {
        XCTAssertNotEqual(
            try ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(),
            try ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier()
        )
    }

    func testGeneratedCodeVerifierHasLength43() throws {
        // 43 is the recommended lenght. See https://www.rfc-editor.org/rfc/rfc7636#section-4.1
        XCTAssertEqual(try ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue.count, 43)
        XCTAssertEqual(try ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue.count, 43)
    }

    func testCodeVerifierIsRandomStringWithURLSafeCharacters() throws {
        // Notice we call `inverted` and assert nil to make sure none of the characters that are
        // not URL safe are in the generated string.
        //
        // Given the generation is random, we repeat the test twice to increase reliability.
        XCTAssertNil(
            try ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
        XCTAssertNil(
            try ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
    }

    // MARK: –

    func testCodeVerifierInitFailsWithValueShorterThan43() {
        // 43 is the minimmum lenght from the spec
        XCTAssertNil(ProofKeyForCodeExchange.CodeVerifier(value: ""))
        XCTAssertNil(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(42)))
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(43))?.rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(44))?.rawValue.count, 44)
    }

    func testCodeVerifierInitFailsWithValueLongerThan128() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(127))?.rawValue.count, 127)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(128))?.rawValue.count, 128)
        XCTAssertNil(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(129)))
    }

    func testCodeVerifierInitFailsWithInvalidCharacters() {
        XCTAssertNil(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(43) + "?"))
        XCTAssertNil(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(43) + "^"))
        XCTAssertNil(ProofKeyForCodeExchange.CodeVerifier(value: "a".repeated(43) + "🤔"))
    }
}

private extension String {

    func repeated(_ times: Int) -> String {
        (0..<times).map { _ in self }.joined()
    }
}
