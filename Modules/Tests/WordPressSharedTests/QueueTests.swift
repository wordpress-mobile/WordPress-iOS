import Testing
@testable import WordPressShared

final class QueueTests {
    private var queue = Queue<Int>()

    @Test func testNewQueueIsEmpty() {
        let item = queue.pop()
        #expect(item == nil)
    }

    @Test func testSingleItemAddedToQueue() {
        queue.push(1)
        let item = queue.pop()
        #expect(item == 1)
    }

    @Test func testSingleItemRemovedFromQueue() {
        queue.push(1)

        let item = queue.pop()
        let nothing = queue.pop()
        #expect(item != nil)
        #expect(nothing == nil)
    }

    @Test func testMultipleItemsReturnedInFIFOOrder() {
        queue.push(1)
        queue.push(2)
        queue.push(3)

        let item1 = queue.pop()
        let item2 = queue.pop()

        queue.push(4)

        let item3 = queue.pop()
        let item4 = queue.pop()
        let item5 = queue.pop()

        #expect(item1 == 1)
        #expect(item2 == 2)
        #expect(item3 == 3)
        #expect(item4 == 4)
        #expect(item5 == nil)
    }

    @Test func testRemoveAllEmptiesTheQueue() {
        // Given
        queue.push(1)
        queue.push(2)
        queue.push(3)

        // When
        queue.removeAll()

        // Then
        #expect(queue.pop() == nil)
    }

    @Test func testRemoveAllRemovesElementsMatchingThePredicate() {
        // Given
        queue.push(1)
        queue.push(2)
        queue.push(3)

        // When
        queue.removeAll { $0 >= 2 }

        // Then
        #expect(queue.pop() == 1)
        #expect(queue.pop() == nil)
    }
}
