import XCTest
@testable import WordPressShared

class DebouncerTests: XCTestCase {

    /// Tests that the debouncer runs within an accurate time range normally.
    ///
    func testDebouncerRunsNormally() {
        let timerDelay = 0.5
        let allowedError = 0.5
        let minDelay = timerDelay * (1 - allowedError)
        let maxDelay = timerDelay * (1 + allowedError)
        let testTimeout = maxDelay + 0.01

        let startDate = Date()
        let debouncerHasRunAccurately = XCTestExpectation(description: "The debouncer should run within an accurate time range normally.")

        let debouncer = Debouncer(delay: timerDelay) {
            let actualDelay = Date().timeIntervalSince(startDate)

            if actualDelay >= minDelay
                && actualDelay <= maxDelay {

                debouncerHasRunAccurately.fulfill()
            } else {
                XCTFail("Actual delay was: \(actualDelay))")
            }
        }
        debouncer.call()

        wait(for: [debouncerHasRunAccurately], timeout: testTimeout)
    }

    /// Tests that the debouncer runs immediately if its released.
    ///
    func testDebouncerRunsImmediatelyIfReleased() {
        let debouncerHasRun = XCTestExpectation(description: "The debouncer should run immediately if it's released")

        Debouncer(delay: 0.5) {
            debouncerHasRun.fulfill()
        }.call()

        wait(for: [debouncerHasRun], timeout: 0)
    }

    /// Tests that we can cancel the debouncer's operation.
    ///
    func testDebouncerCanBeCancelled() {
        let debouncerDelay = 0.2
        let testTimeout = debouncerDelay * 2
        let debouncerHasRun = XCTestExpectation(description: "The debouncer's operation should be cancellable.")
        debouncerHasRun.isInverted = true

        let debouncer = Debouncer(delay: debouncerDelay) {
            debouncerHasRun.fulfill()
        }

        debouncer.call()
        debouncer.cancel()

        wait(for: [debouncerHasRun], timeout: testTimeout)
    }

    /// Tests that the debouncer works fine when used with an ad hoc callback.
    ///
    func testDebouncerWithAdHocCallback() {
        let timerDelay = 0.5
        let allowedError = 0.5
        let minDelay = timerDelay * (1 - allowedError)
        let maxDelay = timerDelay * (1 + allowedError)
        let testTimeout = maxDelay + 0.01

        let startDate = Date()
        let debouncerHasRunAccurately = XCTestExpectation(description: "The debouncer should run within an accurate time range normally.")

        let debouncer = Debouncer(delay: timerDelay)
        debouncer.call() {
            let actualDelay = Date().timeIntervalSince(startDate)

            if actualDelay >= minDelay
                && actualDelay <= maxDelay {

                debouncerHasRunAccurately.fulfill()
            } else {
                XCTFail("Actual delay was: \(actualDelay))")
            }
        }

        wait(for: [debouncerHasRunAccurately], timeout: testTimeout)
    }
}
