import XCTest
@testable import WordPress

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
}
