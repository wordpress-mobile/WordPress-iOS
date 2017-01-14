import Foundation
import XCTest
@testable import WordPress


// MARK: - NSAttributedString Unit Tests
//
open class NSAttributedStringTests: XCTestCase {
    /// Verifies that `trimNewLines` effectively nukes leading newline characters.
    ///
    func testTrimNewlinesEffectivelyNukesLeadingNewlines() {
        let expected = "Lord Yosemite SHOULD be a Game of Thrones Character"
        let input = NSAttributedString(string: "\n\n\n\(expected)")

        XCTAssertEqual(input.trimNewlines().string, expected)
    }

    /// Verifies that `trimNewLines` effectively nukes trailing newline characters.
    ///
    func testTrimNewlinesEffectivelyNukesTrailingNewlines() {
        let expected = "Lord Yosemite SHOULD be a Game of Thrones Character"
        let input = NSAttributedString(string: "\(expected)\n\n\n")

        XCTAssertEqual(input.trimNewlines().string, expected)
    }
}
