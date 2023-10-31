import XCTest
@testable import WordPress

class CollectionRotateTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    func testRotateOne() {
        let beforeCollection = [1, 2, 3, 4, 5]
        let afterCollection = beforeCollection.rotateLeft(1)
        XCTAssertEqual([2, 3, 4, 5, 1], afterCollection)
    }

    func testRotateSame() {
        let beforeCollection = [1, 2, 3, 4, 5]
        let afterCollection = beforeCollection.rotateLeft(0)
        XCTAssertEqual(beforeCollection, afterCollection)
    }

    func testRotateNegative() {
        let beforeCollection = [1, 2, 3, 4, 5]
        let afterCollection = beforeCollection.rotateLeft(-1)
        XCTAssertEqual([2, 3, 4, 5, 1], afterCollection)
    }

    func testRotateOutOfIndex() {
        let beforeCollection = [1, 2, 3, 4, 5]
        let afterCollection = beforeCollection.rotateLeft(5)
        XCTAssertEqual([1, 2, 3, 4, 5], afterCollection)
    }
}
