import Foundation
import Testing

@testable import WordPressShared

struct StringHelperTests {

    // Note:
    // Specially extra aligned for my RWC friends. With love.
    //
    let links = ["http://www.google.com", "http://www.automattic.com", "http://wordpress.com?some=random", "http://wordpress.com/path/to/nowhere", "http://wordpress.com/", "https://www.wordpress.blog"]
    let linkText = ["www.google.com", "www.automattic.com", "wordpress.com", "wordpress.com/path/to/nowhere", "wordpress.com/", "www.wordpress.blog"]

    let text = " Lorem Ipsum Matarem Les Idiotum Sarasum Zorrentum Modus Operandum "
    let anchor = "<a href=\"%@\">%@</a>"

    @Test func testLinkifyingPlainLinks() {
        var count = 0
        for link in links {
            let linkified = String(format: anchor, link, linkText[count])
            #expect(link.stringWithAnchoredLinks() == linkified, "Oh noes!")
            count += 1
        }
    }

    @Test func testLinkifyingLinksWithinText() {
        var plain = String()
        var linkified = String()

        var count = 0
        for link in links {
            plain += text + link
            linkified += text + String(format: anchor, link, linkText[count])
            count += 1
        }

        #expect(plain.stringWithAnchoredLinks() == linkified, "Oh noes!")
    }

    @Test func testLinkifyingPlainText() {
        #expect(text.stringWithAnchoredLinks() == text, "Oh noes!")
    }

    @Test func testTrim() {
        let trimmedString = "string string"
        let sourceString = "   \(trimmedString)   "
        #expect(trimmedString == sourceString.trim())
    }

    @Test func testRemovePrefix() {
        let string = "X-Post: This is a test"
        #expect("This is a test" == string.removingPrefix("X-Post: "))
        #expect(string == string.removingPrefix("Something Else"))
    }

    @Test func testRemoveSuffix() {
        let string = "http://example.com/"
        #expect("http://example.com" == string.removingSuffix("/"))
        #expect("http://example" == string.removingSuffix(".com/"))
        #expect(string == string.removingSuffix(".org/"))
    }

    @Test func testRemovePrefixPattern() {
        let string = "X-Post: This is a test"
        #expect("This is a test" == (try! string.removingPrefix(pattern: "X-.*?: +")))
        #expect(string == (try! string.removingPrefix(pattern: "Th.* ")))
    }

    @Test func testRemoveSuffixPattern() {
        let string = "X-Post: This is a test"
        #expect("X-Post: This is" == (try! string.removingSuffix(pattern: "( a)? +test")))
        #expect(string == (try! string.removingSuffix(pattern: "Th.* ")))
    }
}
