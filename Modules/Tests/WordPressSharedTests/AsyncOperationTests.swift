import Foundation
import Testing
import WordPressShared

struct AsyncOperationTests {
    let operation = AsyncOperation()

    @Test func testIsAsynchronous() {
        #expect(operation.isAsynchronous)
    }

    @Test func testDefaultState() {
        #expect(operation.state == AsyncOperation.State.isReady)
    }

    @Test func testIsExecutingState() {
        operation.start()
        #expect(operation.isExecuting)
    }

    @Test func testIsFinishedState() {
        operation.cancel()
        operation.start()
        #expect(operation.isFinished)
    }
}
