import XCTest
@testable import WordPressShared

class StringRemovingMatchesTests: XCTestCase {

    func testStringRemovingMatches() {
        let initial = "<p>Some Content</p>"
        let pattern = "<p>"
        let expected = "Some Content</p>"

        let final = initial.removingMatches(pattern: pattern)

        XCTAssertEqual(final, expected)
    }

    func testStringRemovingMatchesWithEmojis() {
        let initial = "🌎world🌎"
        let pattern = "🌎"
        let expected = "world"

        let final = initial.removingMatches(pattern: pattern)

        XCTAssertEqual(final, expected)
    }

    func testStringRemovingMatchesWithEmojis2() {
        let initial = "🌎world🌎"
        let pattern = "world"
        let expected = "🌎🌎"

        let final = initial.removingMatches(pattern: pattern)

        XCTAssertEqual(final, expected)
    }
}
