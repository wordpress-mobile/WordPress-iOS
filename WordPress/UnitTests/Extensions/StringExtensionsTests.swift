import Foundation
import XCTest
@testable import WordPress


class StringExtensionsTests: XCTestCase {
    // Note:
    // Specially extra aligned for my RWC friends. With love.
    //
    fileprivate let links   = ["http://www.google.com", "http://www.automattic.com", "http://wordpress.com?some=random", "http://wordpress.com/path/to/nowhere", "http://wordpress.com/", "https://www.wordpress.blog"]
    fileprivate let linkText = ["www.google.com", "www.automattic.com", "wordpress.com", "wordpress.com/path/to/nowhere", "wordpress.com/", "www.wordpress.blog"]

    fileprivate let text    = " Lorem Ipsum Matarem Les Idiotum Sarasum Zorrentum Modus Operandum "
    fileprivate let anchor  = "<a href=\"%@\">%@</a>"


    func testLinkifyingPlainLinks() {
        var count = 0
        for link in links {
            let linkified = String(format: anchor, link, linkText[count])
            XCTAssertEqual(link.stringWithAnchoredLinks(), linkified, "Oh noes!")
            count += 1
        }
    }

    func testLinkifyingLinksWithinText() {
        var plain       = String()
        var linkified   = String()

        var count = 0
        for link in links {
            plain       += text + link
            linkified   += text + String(format: anchor, link, linkText[count])
            count += 1
        }

        XCTAssertEqual(plain.stringWithAnchoredLinks(), linkified, "Oh noes!")
    }

    func testLinkifyingPlainText() {
        XCTAssertEqual(text.stringWithAnchoredLinks(), text, "Oh noes!")
    }
}
