import Testing
import WordPressShared

struct StringRankedSearchTests {
    @Test func testScoreInRange() {
        // High confidence
        expectInRange(0.8...1.0, score("Appleseed", "Appleseed"))
        expectInRange(0.8...1.0, score("John Appleseed", "Appleseed"))
        expectInRange(0.8...1.0, score("John Appleseed", "John"))
        expectInRange(0.8...1.0, score("John Appleseed", "App"))
        expectInRange(0.8...1.0, score("John O'Appleseed", "App"))
        expectInRange(0.8...1.0, score("john-appleseed", "j-a"))
        expectInRange(0.8...1.0, score("#john-appleseed", "john"))
        expectInRange(0.8...1.0, score("John Appleseed", "Apseed"))

        // Medium confidence
        expectInRange(0.5...0.8, score("John Appleseed", "A"))
        expectInRange(0.5...0.8, score("John Appleseed", "Ap"))
        expectInRange(0.5...0.8, score("John Appleseed", "ohn"))
        expectInRange(0.5...0.8, score("#john-appleseed", "j-a"))
        expectInRange(0.5...0.8, score("John Appleseed", "applex"))

        // Low confidence
        expectInRange(0.2...0.5, score("John Appleseed", "Ae"))
        expectInRange(0.2...0.5, score("John Appleseed", "Jn"))

        // Very low confidence
        expectInRange(0.0...0.2, score("John Appleseed", "o"))
        expectInRange(0.0...0.2, score("John Appleseed", "X"))
        expectInRange(0.0...0.2, score("John Appleseed", "x"))
        expectInRange(0.0...0.2, score("John Appleseed", "applexx"))
    }

    @Test func testBonuses() {
        // Bonus for the number of the matching words in the input.
        #expect(score("John Appleseed", "App") < score("Appleseed", "App"))

        // Bonus for distance between matches
        #expect(score("John Xxxx Appleseed", "John Appleseed") < score("John Appleseed Xxxx", "John Appleseed"))

        // Bonus for distance between matches
        #expect(score("John Xxxx Appleseed", "John Appleseed") < score("John Appleseed Xxxx", "John Appleseed"))

        // Bonus for distance between matches
        #expect(score("John Xxxx Appleseed", "John Appleseed") < score("Xxxx John Appleseed", "John Appleseed"))

        // Bonus for more characters in a row
        #expect(score("Apxplesee", "App") < score("Appleseed", "App"))

        // Bonus for more characters in a row is higher than the penalty for a number of matches
        #expect(score("Apxplesee", "App") < score("John Appleseed", "App"))

        // Bonus for more characters in a row is higher than the penalty for mismatches case.
        #expect(score("Apxplesee", "App") < score("appleseed", "App"))

        // The diacritics are considered a match
        #expect(score("Kxhu", "Kahu") < score("Kāhu", "Kahu"))

        // Bonus for exact match diacritics are present
        #expect(score("Kāhu", "Kahu") < score("Kahu", "Kahu"))

        // Bonus for exact match diacritics are present
        #expect(score("Kāhu", "Kahu") < score("Kāhu", "Kāhu"))

        // Bonus for number length match
        #expect(score("john-appleseed-xxxx", "project") < score("john-appleseed", "project"))
    }
}

private func score(_ lhs: String, _ rhs: String) -> Double {
    StringRankedSearch(searchTerm: rhs).score(for: lhs)
}

private func expectInRange<T: Comparable>(
    _ range: some RangeExpression<T>,
    _ value: T,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(range.contains(value), "(\"\(value)\") is not in (\"\(range)\")", sourceLocation: sourceLocation)
}
