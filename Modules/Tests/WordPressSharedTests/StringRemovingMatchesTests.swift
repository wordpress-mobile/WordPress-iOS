import Testing
@testable import WordPressShared

struct StringRemovingMatchesTests {

    @Test func testStringRemovingMatches() {
        let initial = "<p>Some Content</p>"
        let pattern = "<p>"
        let expected = "Some Content</p>"

        let final = initial.removingMatches(pattern: pattern)

        #expect(final == expected)
    }

    @Test func testStringRemovingMatchesWithEmojis() {
        let initial = "🌎world🌎"
        let pattern = "🌎"
        let expected = "world"

        let final = initial.removingMatches(pattern: pattern)

        #expect(final == expected)
    }

    @Test func testStringRemovingMatchesWithEmojis2() {
        let initial = "🌎world🌎"
        let pattern = "world"
        let expected = "🌎🌎"

        let final = initial.removingMatches(pattern: pattern)

        #expect(final == expected)
    }
}
