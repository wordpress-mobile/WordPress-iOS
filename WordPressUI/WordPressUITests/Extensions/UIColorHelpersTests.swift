import XCTest
import WordPressUIKit

class UIColorHelpersTests: XCTestCase {

    func testHexString() {
        XCTAssertEqual(UIColor.red.hexString().lowercased(), "ff0000")

        // hexString works for RGB and grayscale colors
        XCTAssertEqual(UIColor.black.hexString().lowercased(), "000000")
        XCTAssertEqual(UIColor(white: 1, alpha: 1).hexString().lowercased(), "ffffff")
    }
}
