import Foundation
import UIKit
import XCTest
import WordPressShared
import WordPressSharedUI
@testable import WordPress

class RichContentFormatterTests: XCTestCase {

    func testResizeGalleryImageURLsForContentPublic() {
        guard
            let path = Bundle(for: type(of: self)).path(forResource: "gallery-reader-post-public", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let postDict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary,
            let content = postDict.object(forKey: "content") as? NSString else {
                XCTFail()
                return
        }

        // A fixed 390×844 pt, 3x display, so the expected size doesn't depend on the test host's screen.
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        let scale: CGFloat = 3
        let resultContent = RichContentFormatter.resizeGalleryImageURL(
            content as String,
            isPrivateSite: false,
            bounds: bounds,
            traitCollection: UITraitCollection(displayScale: scale)
        ) as NSString
        let scaledSize = bounds.size.applying(CGAffineTransform(scaleX: scale, y: scale))

        // Verify that the image source was updated with a Photon-friendly sized URL
        let sourceStr = "src=\"https://lanteanartest.files.wordpress.com/2016/07/image217.png?w=1024&#038;h=1365\""
        XCTAssertTrue(content.contains(sourceStr))
        XCTAssertFalse(resultContent.contains(sourceStr))
        let expectedURL = "src=\"https://i0.wp.com/lanteanartest.files.wordpress.com/2016/07/image217.png?quality=80&resize=\(Int(scaledSize.width)),\(Int(scaledSize.height))&ssl=1\""
        XCTAssertTrue(resultContent.contains(expectedURL))
    }

    func testResizeGalleryImageURLsForContentPrivate() {
        guard
            let path = Bundle(for: type(of: self)).path(forResource: "gallery-reader-post-private", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let postDict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary,
            let content = postDict.object(forKey: "content") as? NSString else {
                XCTFail()
                return
        }

        // A fixed 390×844 pt, 3x display, so the expected size doesn't depend on the test host's screen.
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        let scale: CGFloat = 3
        let resultContent = RichContentFormatter.resizeGalleryImageURL(
            content as String,
            isPrivateSite: true,
            bounds: bounds,
            traitCollection: UITraitCollection(displayScale: scale)
        ) as NSString
        let scaledSize = bounds.size.applying(CGAffineTransform(scaleX: scale, y: scale))

        // Verify that the image source was updated with a Photon-friendly sized URL
        let sourceStr = "src=\"https://picklessaltyporkvonhausen.files.wordpress.com/2016/07/img_8961.jpg?w=181&#038;h=135&#038;crop=1\""
        XCTAssertTrue(content.contains(sourceStr))
        XCTAssertFalse(resultContent.contains(sourceStr))
        let expectedURL = "src=\"https://picklessaltyporkvonhausen.files.wordpress.com/2016/07/img_8961.jpg?h=\(Int(scaledSize.height))&w=\(Int(scaledSize.width))\""
        XCTAssertTrue(resultContent.contains(expectedURL))
    }
}
