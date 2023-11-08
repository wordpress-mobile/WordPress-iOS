import XCTest
@testable import JetpackStatsWidgetsCore

final class MyLibraryTests: XCTestCase {
    func testExample() throws {
        // Fail on purpose to ensure we can catch failures
        XCTAssertEqual(Dummy().salutation, "Howdy")
    }
}
