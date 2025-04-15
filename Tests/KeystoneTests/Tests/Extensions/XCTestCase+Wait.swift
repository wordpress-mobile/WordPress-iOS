import XCTest

extension XCTestCase {
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")

        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()
        }

        // We wait for the duration + 1 second to allow some buffer in case the dispatched block gets
        // delayed by GCD for any reason for even 1 microsecond.
        waitForExpectations(timeout: duration + 1)
    }
}
