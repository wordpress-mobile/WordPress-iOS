import UIKit
import XCTest
import WordPress

class ReaderHelperTests: XCTestCase {

    // Tests that a UIActivityViewController is returned from the helper
    func testShareControllerCreated() {
        var controller = ReaderHelpers.shareController("test", summary:"test", tags:"test", link:"test")
        XCTAssertNotNil(controller, "Controller should not be nil")

        controller = ReaderHelpers.shareController("", summary:"", tags:"", link:"")
        XCTAssertNotNil(controller, "Controller should not be nil")

        controller = ReaderHelpers.shareController(nil, summary:nil, tags:nil, link:nil)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

}
