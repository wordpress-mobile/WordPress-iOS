import UIKit
import XCTest
@testable import WordPress

class PostSharingControllerTests: XCTestCase {

    // Tests that a UIActivityViewController is returned from the helper
    func testShareControllerCreated() {

        let sharingController = PostSharingController()

        var controller = sharingController.shareController("test", summary:"test", tags:"test", link:"test")
        XCTAssertNotNil(controller, "Controller should not be nil")

        controller = sharingController.shareController("", summary:"", tags:"", link:"")
        XCTAssertNotNil(controller, "Controller should not be nil")

        controller = sharingController.shareController(nil, summary:nil, tags:nil, link:nil)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

}
