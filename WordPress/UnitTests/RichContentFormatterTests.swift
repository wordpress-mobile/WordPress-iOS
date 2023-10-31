import Foundation
import UIKit
import XCTest
import WordPressShared
@testable import WordPress

class RichContentFormatterTests: XCTestCase {

    func testResizeGalleryImageURLsForContentPublic() {
        guard
            let path = Bundle(for: type(of: self)).path(forResource: "gallery-reader-post-public", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let postDict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary,
            let content = postDict.object(forKey: "content") as? NSString,
            let window = UIApplication.shared.mainWindow else {
                XCTFail()
                return
        }

        let resultContent = RichContentFormatter.resizeGalleryImageURL(content as String, isPrivateSite: false) as NSString
        let imageSize = window.frame.size
        let scale = UIScreen.main.scale
        let scaledSize = imageSize.applying(CGAffineTransform(scaleX: scale, y: scale))

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
            let content = postDict.object(forKey: "content") as? NSString,
            let window = UIApplication.shared.mainWindow else {
                XCTFail()
                return
        }

        let resultContent = RichContentFormatter.resizeGalleryImageURL(content as String, isPrivateSite: true) as NSString
        let imageSize = window.frame.size
        let scale = UIScreen.main.scale
        let scaledSize = imageSize.applying(CGAffineTransform(scaleX: scale, y: scale))

        // Verify that the image source was updated with a Photon-friendly sized URL
        let sourceStr = "src=\"https://picklessaltyporkvonhausen.files.wordpress.com/2016/07/img_8961.jpg?w=181&#038;h=135&#038;crop=1\""
        XCTAssertTrue(content.contains(sourceStr))
        XCTAssertFalse(resultContent.contains(sourceStr))
        let expectedURL = "src=\"https://picklessaltyporkvonhausen.files.wordpress.com/2016/07/img_8961.jpg?h=\(Int(scaledSize.height))&w=\(Int(scaledSize.width))\""
        XCTAssertTrue(resultContent.contains(expectedURL))
    }
}
