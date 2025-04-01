import XCTest
@testable import WordPressAuthenticator

// MARK: - WordPressAuthenticator Display Text Unit Tests
//
class WordPressAuthenticatorDisplayTextTests: XCTestCase {
    /// Default display text instance
    ///
    let displayTextDefaults = WordPressAuthenticatorDisplayStrings.defaultStrings

    /// Verifies that values in defaultText are not nil
    ///
    func testThatDefaultTextValuesAreNotNil() {
        XCTAssertNotNil(displayTextDefaults.emailLoginInstructions)
        XCTAssertNotNil(displayTextDefaults.siteLoginInstructions)
    }

    /// Verifies that values in defaultText are not empty strings
    ///
    func testThatDefaultTextValuesAreNotEmpty() {
        XCTAssertFalse(displayTextDefaults.emailLoginInstructions.isEmpty)
        XCTAssertFalse(displayTextDefaults.siteLoginInstructions.isEmpty)
    }
}
