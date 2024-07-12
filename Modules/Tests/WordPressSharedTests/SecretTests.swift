import WordPressShared
import XCTest

class SecretTests: XCTestCase {
    func testSecretDescription() {
        let secret = Secret("my secret")
        XCTAssertEqual("--redacted--", secret.description, "Description should be redacted")
    }

    func testSecretDebugDescription() {
        let secret = Secret("my secret")
        XCTAssertEqual("--redacted--", secret.debugDescription, "Debug description should be redacted")
    }

    func testSecretMirror() {
        let secret = Secret("my secret")
        XCTAssertEqual("--redacted--", String(reflecting: secret), "Mirror should be redacted")
    }

    func testSecretUnwrapsValue() {
        let secret = Secret("my secret")
        XCTAssertEqual("my secret", secret.secretValue, "secretValue should not be redacted")
    }
}
