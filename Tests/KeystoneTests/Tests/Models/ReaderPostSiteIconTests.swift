import UIKit
import XCTest

@testable import WordPress
@testable import WordPressData

final class ReaderPostSiteIconTests: CoreDataTestCase {
    func testSiteIconURL() throws {
        let traitCollection = UITraitCollection(displayScale: 2)
        let post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.entityName(), into: mainContext) as! ReaderPost
        XCTAssertNil(post.getSiteIconURL(size: 50, traitCollection: traitCollection))

        post.siteIconURL = "http://example.com/icon.png"
        XCTAssertEqual(
            post.getSiteIconURL(size: 50, traitCollection: traitCollection),
            URL(string: "http://example.com/icon.png")
        )

        post.siteIconURL = "https://gravatar.com/blavatar/icon.png"
        let scaledURL = try XCTUnwrap(post.getSiteIconURL(size: 50, traitCollection: traitCollection))
        let components = try XCTUnwrap(URLComponents(url: scaledURL, resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []
        XCTAssertEqual(queryItems.count, 2)
        XCTAssertEqual(queryItems.first(where: { $0.name == "s" })?.value, "100")
        XCTAssertEqual(queryItems.first(where: { $0.name == "d" })?.value, "404")
    }
}
