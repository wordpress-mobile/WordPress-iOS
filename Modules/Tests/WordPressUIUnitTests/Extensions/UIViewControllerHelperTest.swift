import XCTest
@testable import WordPressUI

class UIViewControllerHelperTest: XCTestCase {
    let vca = UIViewController()
    let vcb = UIViewController()

    func testAddChildViewController() {
        vca.add(vcb)
        XCTAssertFalse(vca.children.isEmpty, "vca.children shouldn't be empty")
    }

    func testRemoveChildViewController() {
        vca.remove(vcb)
        XCTAssertTrue(vca.children.isEmpty, "vca.children should be empty")
    }
}
