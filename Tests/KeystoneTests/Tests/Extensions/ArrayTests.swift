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

    func testDifferentIndicesReturnsEmptyWithSameArray() {
        let test = [1, 2, 3]
        let result = test.differentIndices(test)
        XCTAssert(result.isEmpty)
    }

    func testDifferentIndicesReturnsDifferencesWhenOtherSmaller() {
        let test = [1, 2, 3]
        let other = [1]
        let result = test.differentIndices(other)
        XCTAssertEqual(result, [1, 2])
    }

    func testDifferentIndicesReturnsDifferencesWhenOtherLarger() {
        let test = [1, 2, 3]
        let other = [1, 0, 3, 4]
        let result = test.differentIndices(other)
        XCTAssertEqual(result, [1])
    }

    func testSortedGroupEmptyArray() {
        let test = [TestElement]()
        let result = test.sortedGroup(keyPath: \TestElement.key)
        XCTAssertEqual(result.count, 0)
    }

    func testSortedGroupCase1() {
        let test: [TestElement] = [TestElement(key: "a", value: 1), TestElement(key: "a", value: 2)]
        let result = test.sortedGroup(keyPath: \TestElement.key)
        XCTAssertEqual(result[0].0, test[0].key)
        XCTAssertEqual(result[0].1[0], test[0])
        XCTAssertEqual(result[0].1[1], test[1])
    }

    func testSortedGroupCase2() {
        let test: [TestElement] = [TestElement(key: "a", value: 1), TestElement(key: "b", value: 1)]
        let result = test.sortedGroup(keyPath: \TestElement.key)
        XCTAssertEqual(result[0].0, test[0].key)
        XCTAssertEqual(result[1].0, test[1].key)
        XCTAssertEqual(result[0].1[0], test[0])
        XCTAssertEqual(result[1].1[0], test[1])
    }

    func testSortedGroupCase3() {
        let test: [TestElement] = [TestElement(key: "a", value: 1), TestElement(key: "b", value: 1),
                                   TestElement(key: "b", value: 2), TestElement(key: "c", value: 1)]
        let result = test.sortedGroup(keyPath: \TestElement.key)
        XCTAssertEqual(result[0].0, test[0].key)
        XCTAssertEqual(result[1].0, test[1].key)
        XCTAssertEqual(result[2].0, test[3].key)
        XCTAssertEqual(result[0].1[0], test[0])
        XCTAssertEqual(result[1].1[0], test[1])
        XCTAssertEqual(result[1].1[1], test[2])
        XCTAssertEqual(result[2].1[0], test[3])
    }

    func testUniqueRemovesDuplicates() {
        let test = ["🦄", "🦄", "🌈"]

        let result = test.unique

        XCTAssertTrue(result.count == 2 && result.contains("🦄") && result.contains("🌈"))
    }

}

class TestElement: Equatable {
    var key: String
    var value: Int

    init(key: String, value: Int) {
        self.key = key
        self.value = value
    }
}

func ==(lhs: TestElement, rhs: TestElement) -> Bool {
    return lhs.key == rhs.key && lhs.value == rhs.value
}
