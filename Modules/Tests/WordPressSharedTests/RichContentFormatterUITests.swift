import XCTest
@testable import WordPressShared
@testable import WordPressSharedUI

class RichContentFormatterUITests: XCTestCase {

    func testResizeGalleryImageURLsForContentEmptyString() {
        XCTAssertTrue("" == RichContentFormatter.resizeGalleryImageURL("", isPrivateSite: false))
    }
}
