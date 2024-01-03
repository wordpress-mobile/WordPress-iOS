import XCTest

public extension XCUIElement {

    /// Abstraction do describe possible "states" an `XCUIElement` can be in.
    ///
    /// The goal of this `enum` is to make checking against the possible states a safe operation thanks to the compiler enforcing all and only the states represented by the `enum` `case`s are handled.
    enum State {
        case exists
        case dismissed
        case selected
    }

    /// Attempt to tap `self` until the given `XCUIElement` is in the given `State` or the `maxRetries` number of retries has been reached.
    ///
    /// Useful to make tests robusts against UI changes that may have some lag.
    func tapUntil(
        element: XCUIElement,
        matches state: State,
        failureMessage: String,
        maxRetries: Int = 10,
        retryInterval: TimeInterval = 1
    ) {
        tapUntil(
            Condition(element: element, state: state),
            retriedCount: 0,
            failureMessage: failureMessage,
            maxRetries: maxRetries,
            retryInterval: retryInterval
        )
    }

    /// Attempt to tap `self` until its "state" matches `Condition.State` or the `maxRetries` number of retries has been reached.
    ///
    /// Useful to make tests robusts against UI changes that may have some lag.
    func tapUntil(
        _ state: State,
        failureMessage: String,
        maxRetries: Int = 10,
        retryInterval: TimeInterval = 1
    ) {
        tapUntil(
            Condition(element: self, state: state),
            retriedCount: 0,
            failureMessage: failureMessage,
            maxRetries: maxRetries,
            retryInterval: retryInterval
        )
    }

    /// Describe the expectation for a given `XCUIElement` to be in a certain `Condition.State`.
    ///
    /// Example: `Condition(element: myButton, state: .selected)`.
    struct Condition {

        let element: XCUIElement
        let state: XCUIElement.State

        fileprivate func isMet() -> Bool {
            switch state {
            case .exists: return element.exists
            case .dismissed: return element.isHittable == false
            case .selected: return element.isSelected
            }
        }
    }

    private func tapUntil(
        _ condition: Condition,
        retriedCount: Int,
        failureMessage: String,
        maxRetries: Int,
        retryInterval: TimeInterval
    ) {
        guard retriedCount < maxRetries else {
            return XCTFail("\(failureMessage) after \(retriedCount) tries.")
        }

        tap()

        guard condition.isMet() else {
            sleep(UInt32(retryInterval))
            return tapUntil(condition, retriedCount: retriedCount + 1, failureMessage: failureMessage, maxRetries: maxRetries, retryInterval: retryInterval)
        }
    }
}
