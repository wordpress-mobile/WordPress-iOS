import XCTest
@testable import WordPress

class QueueTests: XCTestCase {
    private var queue = Queue<Int>()

    override func setUp() {
        super.setUp()

        queue = Queue<Int>()
    }

    func testNewQueueIsEmpty() {
        let item = queue.pop()
        XCTAssertNil(item)
    }

    func testSingleItemAddedToQueue() {
        queue.push(1)
        let item = queue.pop()
        XCTAssertEqual(item, 1)
    }

    func testSingleItemRemovedFromQueue() {
        queue.push(1)

        let item = queue.pop()
        let nothing = queue.pop()
        XCTAssertNotNil(item)
        XCTAssertNil(nothing)
    }

    func testMultipleItemsReturnedInFIFOOrder() {
        queue.push(1)
        queue.push(2)
        queue.push(3)

        let item1 = queue.pop()
        let item2 = queue.pop()

        queue.push(4)

        let item3 = queue.pop()
        let item4 = queue.pop()
        let item5 = queue.pop()

        XCTAssertEqual(item1, 1)
        XCTAssertEqual(item2, 2)
        XCTAssertEqual(item3, 3)
        XCTAssertEqual(item4, 4)
        XCTAssertNil(item5)
    }

    func testRemoveAllEmptiesTheQueue() {
        // Given
        queue.push(1)
        queue.push(2)
        queue.push(3)

        // When
        queue.removeAll()

        // Then
        XCTAssertNil(queue.pop())
    }

    func testRemoveAllRemovesElementsMatchingThePredicate() {
        // Given
        queue.push(1)
        queue.push(2)
        queue.push(3)

        // When
        queue.removeAll { $0 >= 2 }

        // Then
        XCTAssertEqual(queue.pop(), 1)
        XCTAssertNil(queue.pop())
    }
}
