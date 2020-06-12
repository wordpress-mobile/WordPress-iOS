import XCTest
@testable import MurielColors

final class MurielColorsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MurielColors().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
