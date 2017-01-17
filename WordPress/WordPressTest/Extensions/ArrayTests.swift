import XCTest
import WordPress

class ArrayTests: XCTestCase {
    func testRepeatLast() {
        let array = [1, 2, 3]
        let repeated = Array(array.repeatingLast().prefix(5))
        let expected = [1, 2, 3, 3, 3]
        XCTAssertEqual(expected, repeated)
    }

    func testRepeatLastWithEmptyArray() {
        let array = [Int]()
        let repeated = Array(array.repeatingLast().prefix(5))
        let expected = [Int]()
        XCTAssertEqual(expected, repeated)
    }
}
