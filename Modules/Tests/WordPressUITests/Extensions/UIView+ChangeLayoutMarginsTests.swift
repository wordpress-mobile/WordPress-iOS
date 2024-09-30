import Foundation
import XCTest

@testable import WordPressUI

class UIViewChangeLayoutMarginSTests: XCTestCase {

    var view: UIView!

    override func setUp() {
        view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }

    func testChangeOnlyTopLayoutMargin() {
        view.changeLayoutMargins(top: 10)

        XCTAssertEqual(view.layoutMargins.top, 10)
        XCTAssertEqual(view.layoutMargins.left, 5)
        XCTAssertEqual(view.layoutMargins.bottom, 5)
        XCTAssertEqual(view.layoutMargins.right, 5)
    }

    func testChangeOnlyLeftLayoutMargin() {
        view.changeLayoutMargins(left: 10)

        XCTAssertEqual(view.layoutMargins.top, 5)
        XCTAssertEqual(view.layoutMargins.left, 10)
        XCTAssertEqual(view.layoutMargins.bottom, 5)
        XCTAssertEqual(view.layoutMargins.right, 5)
    }

    func testChangeOnlyBottomLayoutMargin() {
        view.changeLayoutMargins(bottom: 10)

        XCTAssertEqual(view.layoutMargins.top, 5)
        XCTAssertEqual(view.layoutMargins.left, 5)
        XCTAssertEqual(view.layoutMargins.bottom, 10)
        XCTAssertEqual(view.layoutMargins.right, 5)
    }

    func testChangeOnlyRightLayoutMargin() {
        view.changeLayoutMargins(right: 10)

        XCTAssertEqual(view.layoutMargins.top, 5)
        XCTAssertEqual(view.layoutMargins.left, 5)
        XCTAssertEqual(view.layoutMargins.bottom, 5)
        XCTAssertEqual(view.layoutMargins.right, 10)
    }
}
