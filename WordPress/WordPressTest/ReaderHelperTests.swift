import UIKit
import XCTest
import WordPress

class ReaderHelperTests: XCTestCase {

    func testShareControllerCreated() {
        var controller = ReaderHelpers.shareController("test", summary:"test", tags:"test", link:"test")
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

}
