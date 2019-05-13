import UIKit
import XCTest

@testable import WordPress

class PostCellTests: XCTestCase {

    func testIsAUITableViewCell() {
        let postCell = PostCell()

        XCTAssertNotNil(postCell as UITableViewCell)
    }

}
