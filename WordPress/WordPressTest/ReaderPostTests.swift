import UIKit
import XCTest

@testable import WordPress

final class ReaderPostTests: CoreDataTestCase {
    func testSiteIconURL() throws {
        let post = NSEntityDescription.insertNewObject(forEntityName: "ReaderPost", into: mainContext) as! ReaderPost
        XCTAssertNil(post.getSiteIconURL(size: 50))

        post.siteIconURL = "http://example.com/icon.png"
        XCTAssertEqual(post.getSiteIconURL(size: 50), URL(string: "http://example.com/icon.png"))

        post.siteIconURL = "https://gravatar.com/blavatar/icon.png"
        let scaledURL = try XCTUnwrap(post.getSiteIconURL(size: 50))
        let components = try XCTUnwrap(URLComponents(url: scaledURL, resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []
        XCTAssertEqual(queryItems.count, 2)
        XCTAssertEqual(queryItems.first(where: { $0.name == "s" })?.value, Int(50 * UITraitCollection.current.displayScale).description)
        XCTAssertEqual(queryItems.first(where: { $0.name == "d" })?.value, "404")
    }
}
