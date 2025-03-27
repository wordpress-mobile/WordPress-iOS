import XCTest

@testable import WordPressShared

class StringHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Note:
    // Specially extra aligned for my RWC friends. With love.
    //
    let links = ["http://www.google.com", "http://www.automattic.com", "http://wordpress.com?some=random", "http://wordpress.com/path/to/nowhere", "http://wordpress.com/", "https://www.wordpress.blog"]
    let linkText = ["www.google.com", "www.automattic.com", "wordpress.com", "wordpress.com/path/to/nowhere", "wordpress.com/", "www.wordpress.blog"]

    let text = " Lorem Ipsum Matarem Les Idiotum Sarasum Zorrentum Modus Operandum "
    let anchor = "<a href=\"%@\">%@</a>"

    func testLinkifyingPlainLinks() {
        var count = 0
        for link in links {
            let linkified = String(format: anchor, link, linkText[count])
            XCTAssertEqual(link.stringWithAnchoredLinks(), linkified, "Oh noes!")
            count += 1
        }
    }

    func testLinkifyingLinksWithinText() {
        var plain = String()
        var linkified = String()

        var count = 0
        for link in links {
            plain += text + link
            linkified += text + String(format: anchor, link, linkText[count])
            count += 1
        }

        XCTAssertEqual(plain.stringWithAnchoredLinks(), linkified, "Oh noes!")
    }

    func testLinkifyingPlainText() {
        XCTAssertEqual(text.stringWithAnchoredLinks(), text, "Oh noes!")
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
