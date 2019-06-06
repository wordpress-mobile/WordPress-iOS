import XCTest
import WordPressUI

class UIImage_XCAsset: XCTestCase {

    func testGravatarPlaceholderImage() {
        _ = UIImage.gravatarPlaceholderImage
    }

    func testSiteIconPlaceholderImage() {
        _ = UIImage.siteIconPlaceholderImage
    }

    func testLinkFieldImage() {
        _ = UIImage.linkFieldImage
    }
}
