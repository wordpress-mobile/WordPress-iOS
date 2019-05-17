import Foundation
import XCTest

@testable import WordPress

class UIViewLayoutMarginTests: XCTestCase {

    var view: UIView!

    override func setUp() {
        view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }

    func testChangeOnlyTopLayoutMargin() {
        view.setLayoutMargin(top: 10)

        XCTAssertEqual(view.layoutMargins.top, 10)
        XCTAssertEqual(view.layoutMargins.left, 5)
        XCTAssertEqual(view.layoutMargins.bottom, 5)
        XCTAssertEqual(view.layoutMargins.right, 5)
    }

    func testChangeOnlyLeftLayoutMargin() {
        view.setLayoutMargin(left: 10)

        XCTAssertEqual(view.layoutMargins.top, 5)
        XCTAssertEqual(view.layoutMargins.left, 10)
        XCTAssertEqual(view.layoutMargins.bottom, 5)
        XCTAssertEqual(view.layoutMargins.right, 5)
    }

    func testChangeOnlyBottomLayoutMargin() {
        view.setLayoutMargin(bottom: 10)

        XCTAssertEqual(view.layoutMargins.top, 5)
        XCTAssertEqual(view.layoutMargins.left, 5)
        XCTAssertEqual(view.layoutMargins.bottom, 10)
        XCTAssertEqual(view.layoutMargins.right, 5)
    }

    func testChangeOnlyRightLayoutMargin() {
        view.setLayoutMargin(right: 10)

        XCTAssertEqual(view.layoutMargins.top, 5)
        XCTAssertEqual(view.layoutMargins.left, 5)
        XCTAssertEqual(view.layoutMargins.bottom, 5)
        XCTAssertEqual(view.layoutMargins.right, 10)
    }
}
