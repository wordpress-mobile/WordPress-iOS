import Foundation
import Testing
import WordPressShared

// MARK: - NSAttributedString Unit Tests
//
struct NSAttributedStringTests {
    /// Verifies that `trimNewLines` effectively nukes leading newline characters.
    ///
    @Test func testTrimNewlinesEffectivelyNukesLeadingNewlines() {
        let expected = "Lord Yosemite SHOULD be a Game of Thrones Character"
        let input = NSAttributedString(string: "\n\n\n\(expected)")

        #expect(input.trimNewlines().string == expected)
    }

    /// Verifies that `trimNewLines` effectively nukes trailing newline characters.
    ///
    @Test func testTrimNewlinesEffectivelyNukesTrailingNewlines() {
        let expected = "Lord Yosemite SHOULD be a Game of Thrones Character"
        let input = NSAttributedString(string: "\(expected)\n\n\n")

        #expect(input.trimNewlines().string == expected)
    }
}
