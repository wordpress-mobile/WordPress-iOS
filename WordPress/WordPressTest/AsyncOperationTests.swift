import XCTest
@testable import WordPress

class AsyncOperationTests: XCTestCase {
    let operation = AsyncOperation()

    func testIsAsynchronous() {
        XCTAssertTrue(operation.isAsynchronous)
    }

    func testDefaultState() {
        XCTAssertTrue(operation.state == AsyncOperation.State.isReady)
    }

    func testIsExecutingState() {
        operation.start()
        XCTAssertTrue(operation.isExecuting)
    }

    func testIsFinishedState() {
        operation.cancel()
        operation.start()
        XCTAssertTrue(operation.isFinished)
    }
}
