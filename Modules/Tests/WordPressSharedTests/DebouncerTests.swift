import Foundation
import Testing
@testable import WordPressShared

struct DebouncerTests {

    /// Tests that the debouncer runs within an accurate time range normally.
    @Test func testDebouncerRunsNormally() throws {
        let timerDelay = 0.5
        let allowedError = 0.5
        let minDelay = timerDelay * (1 - allowedError)
        let maxDelay = timerDelay * (1 + allowedError)
        let testTimeout = maxDelay + 0.01

        let startDate = Date()
        var actualDelay: TimeInterval?
        let debouncer = Debouncer(delay: timerDelay) {
            actualDelay = Date().timeIntervalSince(startDate)
        }
        debouncer.call()

        // `Debouncer` schedules its callback on a `Timer`, which fires only while its run loop is
        // running. XCTest's `wait(for:)` ran that run loop for us; Swift Testing's async waiting
        // doesn't, so we run it ourselves until the timer fires. `withExtendedLifetime` keeps the
        // debouncer alive across the wait — releasing it early fires the callback from `deinit`.
        withExtendedLifetime(debouncer) {
            let deadline = Date().addingTimeInterval(testTimeout)
            while actualDelay == nil && Date() < deadline {
                RunLoop.current.run(mode: .default, before: deadline)
            }
        }

        let delay = try #require(actualDelay, "The debouncer should run within an accurate time range normally.")
        #expect(delay >= minDelay && delay <= maxDelay, "Actual delay was: \(delay)")
    }

    /// Tests that the debouncer runs immediately if it's released.
    @Test func testDebouncerRunsImmediatelyIfReleased() {
        var didRun = false

        // The debouncer is not retained, so it deallocates at the end of this
        // statement and fires the pending callback synchronously from `deinit`.
        Debouncer(delay: 0.5) {
            didRun = true
        }
        .call()

        #expect(didRun, "The debouncer should run immediately if it's released")
    }

    /// Tests that we can cancel the debouncer's operation.
    @Test func testDebouncerCanBeCancelled() {
        let debouncerDelay = 0.2
        let testTimeout = debouncerDelay * 2

        var didRun = false
        let debouncer = Debouncer(delay: debouncerDelay) {
            didRun = true
        }

        debouncer.call()
        debouncer.cancel()

        // Run the run loop for the full delay so a still-scheduled Timer would fire;
        // a cancelled debouncer must not (see testDebouncerRunsNormally).
        withExtendedLifetime(debouncer) {
            let deadline = Date().addingTimeInterval(testTimeout)
            while Date() < deadline {
                RunLoop.current.run(mode: .default, before: deadline)
            }
        }

        #expect(!didRun, "The debouncer's operation should be cancellable.")
    }

    /// Tests that the debouncer works fine when used with an ad hoc callback.
    @Test func testDebouncerWithAdHocCallback() throws {
        let timerDelay = 0.5
        let allowedError = 0.5
        let minDelay = timerDelay * (1 - allowedError)
        let maxDelay = timerDelay * (1 + allowedError)
        let testTimeout = maxDelay + 0.01

        let startDate = Date()
        var actualDelay: TimeInterval?
        let debouncer = Debouncer(delay: timerDelay)
        debouncer.call {
            actualDelay = Date().timeIntervalSince(startDate)
        }

        // Run the run loop until the Timer fires, as in testDebouncerRunsNormally.
        withExtendedLifetime(debouncer) {
            let deadline = Date().addingTimeInterval(testTimeout)
            while actualDelay == nil && Date() < deadline {
                RunLoop.current.run(mode: .default, before: deadline)
            }
        }

        let delay = try #require(actualDelay, "The debouncer should run within an accurate time range normally.")
        #expect(delay >= minDelay && delay <= maxDelay, "Actual delay was: \(delay)")
    }
}
