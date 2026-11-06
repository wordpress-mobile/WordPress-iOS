import XCTest

extension XCUIElement {
    /// How long a wait pauses between checks.
    private static let pollInterval: TimeInterval = 0.1

    /// How long a wait holds off before its first check.
    ///
    /// Nothing, against the fixtures: they answer at once, so what a screen shows is there as soon
    /// as the screen is.
    ///
    /// Against a real account it's a second, which is what XCTest's own waits take before they
    /// first check. A screen's content arrives over the network some time after the screen does,
    /// and the suites that run against an account lean on that second in places: a list that
    /// reloads as each part of it arrives can move or replace the row a test was about to act on.
    static var firstCheckDelay: TimeInterval = 0

    /// Waits for `condition` to hold, checking it every tenth of a second.
    ///
    /// Use this in place of XCTest's own waits, `waitForExistence(timeout:)` and
    /// `wait(for:toEqual:timeout:)`. Those check once a second, and not for the first time until a
    /// second has passed, so each one takes a second even when what it waits for is already there.
    /// A test makes dozens of them.
    ///
    /// - Returns: Whether the condition held before the timeout.
    func poll(timeout: TimeInterval, until condition: (XCUIElement) -> Bool) -> Bool {
        let deadline = Date(timeIntervalSinceNow: timeout)
        if Self.firstCheckDelay > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: Self.firstCheckDelay))
        }
        while !condition(self) {
            guard Date() < deadline else {
                return false
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: Self.pollInterval))
        }
        return true
    }

    /// Waits for the element to exist. See `poll(timeout:until:)`.
    func pollForExistence(timeout: TimeInterval) -> Bool {
        poll(timeout: timeout) { $0.exists }
    }
}
