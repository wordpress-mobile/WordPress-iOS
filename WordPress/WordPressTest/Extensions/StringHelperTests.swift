import XCTest

@testable import WordPress

class StringHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTrim() {
        let trimmedString = "string string"
        let sourceString = "   \(trimmedString)   "
        XCTAssert(trimmedString == sourceString.trim())
    }
}
