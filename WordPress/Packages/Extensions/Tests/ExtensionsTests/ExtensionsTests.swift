import XCTest
@testable import Extensions

final class ExtensionsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Extensions().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
