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

    func testRemovePrefix() {
        let string = "X-Post: This is a test"
        XCTAssertEqual("This is a test", string.removingPrefix("X-Post: "))
        XCTAssertEqual(string, string.removingPrefix("Something Else"))
    }

    func testRemoveSuffix() {
        let string = "http://example.com/"
        XCTAssertEqual("http://example.com", string.removingSuffix("/"))
        XCTAssertEqual("http://example", string.removingSuffix(".com/"))
        XCTAssertEqual(string, string.removingSuffix(".org/"))
    }

    func testRemovePrefixPattern() {
        let string = "X-Post: This is a test"
        XCTAssertEqual("This is a test", try! string.removingPrefix(pattern: "X-.*?: +"))
        XCTAssertEqual(string, try! string.removingPrefix(pattern: "Th.* "))
    }

    func testRemoveSuffixPattern() {
        let string = "X-Post: This is a test"
        XCTAssertEqual("X-Post: This is", try! string.removingSuffix(pattern: "( a)? +test"))
        XCTAssertEqual(string, try! string.removingSuffix(pattern: "Th.* "))
    }
}
