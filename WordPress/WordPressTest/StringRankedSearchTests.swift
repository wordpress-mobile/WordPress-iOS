import XCTest

@testable import WordPress

final class StringRankedSearchTests: XCTestCase {
    func testScoreInRange() {
        // High confidence
        XCTAssertInRange(0.8...1.0, score("Appleseed", "Appleseed"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "Appleseed"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "John"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "App"))
        XCTAssertInRange(0.8...1.0, score("John O'Appleseed", "App"))
        XCTAssertInRange(0.8...1.0, score("john-appleseed", "j-a"))
        XCTAssertInRange(0.8...1.0, score("#john-appleseed", "john"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "Apseed"))

        // Medium confidence
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "A"))
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "Ap"))
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "ohn"))
        XCTAssertInRange(0.5...0.8, score("#john-appleseed", "j-a"))
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "applex"))

        // Low confidence
        XCTAssertInRange(0.2...0.5, score("John Appleseed", "Ae"))
        XCTAssertInRange(0.2...0.5, score("John Appleseed", "Jn"))

        // Very low confidence
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "o"))
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "X"))
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "x"))
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "applexx"))
    }

    func testBonuses() {
        // Bonus for the number of the matching words in the input.
        XCTAssertLessThan(score("John Appleseed", "App"), score("Appleseed", "App"))

        // Bonus for distance between matches
        XCTAssertLessThan(score("John Xxxx Appleseed", "John Appleseed"), score("John Appleseed Xxxx", "John Appleseed"))

        // Bonus for distance between matches
        XCTAssertLessThan(score("John Xxxx Appleseed", "John Appleseed"), score("John Appleseed Xxxx", "John Appleseed"))

        // Bonus for distance between matches
        XCTAssertLessThan(score("John Xxxx Appleseed", "John Appleseed"), score("Xxxx John Appleseed", "John Appleseed"))

        // Bonus for more characters in a row
        XCTAssertLessThan(score("Apxplesee", "App"), score("Appleseed", "App"))

        // Bonus for more characters in a row is higher than the penalty for a number of matches
        XCTAssertLessThan(score("Apxplesee", "App"), score("John Appleseed", "App"))

        // Bonus for more characters in a row is higher than the penalty for mismatches case.
        XCTAssertLessThan(score("Apxplesee", "App"), score("appleseed", "App"))

        // The diacritics are considered a match
        XCTAssertLessThan(score("Kxhu", "Kahu"), score("Kāhu", "Kahu"))

        // Bonus for exact match diacritics are present
        XCTAssertLessThan(score("Kāhu", "Kahu"), score("Kahu", "Kahu"))

        // Bonus for exact match diacritics are present
        XCTAssertLessThan(score("Kāhu", "Kahu"), score("Kāhu", "Kāhu"))

        // Bonus for number length match
        XCTAssertLessThan(score("john-appleseed-xxxx", "project"), score("john-appleseed", "project"))
    }

    func xtestPerformance() throws {
        measure {
            for _ in 0..<10000 {
                _ = score("John Appleseed", "John")
            }
        }
    }
}

private func score(_ lhs: String, _ rhs: String) -> Double {
    StringRankedSearch(searchTerm: rhs).score(for: lhs)
}

private func XCTAssertInRange<T: Comparable>(_ range: some RangeExpression<T>, _ value: T, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssert(range.contains(value), "(\"\(value)\") is not in (\"\(range)\")", file: file, line: line)
}
