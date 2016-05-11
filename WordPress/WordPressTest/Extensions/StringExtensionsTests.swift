import Foundation
import XCTest
@testable import WordPress


class StringExtensionsTests: XCTestCase
{
    // Note:
    // Specially extra aligned for my RWC friends. With love.
    //
    private let links   = ["http://www.google.com", "http://www.automattic.com", "http://wordpress.com?some=random"]
    private let text    = " Lorem Ipsum Matarem Les Idiotum Sarasum Zorrentum Modus Operandum "
    private let anchor  = "<a href=\"%@\">%@</a>"


    func testLinkifyingPlainLinks() {
        for link in links {
            let linkified = String(format: anchor, link, link)
            XCTAssertEqual(link.stringWithAnchoredLinks(), linkified, "Oh noes!")
        }
    }

    func testLinkifyingLinksWithinText() {
        var plain       = String()
        var linkified   = String()

        for link in links {
            plain       += text + link
            linkified   += text + String(format: anchor, link, link)
        }

        XCTAssertEqual(plain.stringWithAnchoredLinks(), linkified, "Oh noes!")
    }

    func testLinkifyingPlainText() {
        XCTAssertEqual(text.stringWithAnchoredLinks(), text, "Oh noes!")
    }
}
