import XCTest

@testable import WordPress

final class StringRankedSearchTests: CoreDataTestCase {
    func testStringScore() throws {
        func score(_ lhs: String, _ rhs: String) -> Double {
            StringRankedSearch(searchTerm: rhs).score(for: lhs)
        }

        XCTAssertLessThan(score("John Appleseed", "x"), 0.3)
        XCTAssertGreaterThan(score("John Appleseed", "o"), 0.3)
        XCTAssertGreaterThan(score("John Appleseed", "Jo"), 0.3)
        XCTAssertGreaterThan(score("John Appleseed", "jo"), 0.3)
        XCTAssertGreaterThan(score("John Appleseed", "ohn"), 0.3)
        XCTAssertGreaterThan(score("John Appleseed", "App"), 0.3)
        XCTAssertGreaterThan(score("John Appleseed", "ppl"), 0.3)

        XCTAssertLessThan(score("John Appleseed", "x"), score("John Appleseed", "o"))
        XCTAssertLessThan(score("John Appleseed", "o"), score("John Appleseed", "j"))
        XCTAssertLessThan(score("John Appleseed", "j"), score("John Appleseed", "J"))
        XCTAssertLessThan(score("John Appleseed", "j"), score("John Appleseed", "jo"))
        XCTAssertLessThan(score("John Appleseed", "jh"), score("John Appleseed", "jo"))
        XCTAssertLessThan(score("John Appleseed", "j"), score("John Appleseed", "jo"))
        XCTAssertLessThan(score("John Appleseed", "jh"), score("John Appleseed", "jhn"))
        XCTAssertLessThan(score("John xAppleseed", "App"), score("John O'Appleseed", "app"))
        XCTAssertLessThan(score("Andrew xAppleseed", "App"), score("Andrew O'Appleseed", "app"))
        XCTAssertLessThan(score("project-thread-weekly", "project"), score("project-thread", "project"))
    }
}
