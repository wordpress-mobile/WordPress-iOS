import Foundation
import WordPressShared

/// A delayed action implemented using GCD
///
/// This class will perform the given action after the given delay, unless it is
/// canceled first.
///
/// - Example: Create an action and cancel it.
///
///     // Print "action" after 5 seconds
///     let action = DispatchDelayedAction(delay: 5) { print("action") }
///     // Actually, cancel
///     action.cancel()
///
struct DispatchDelayedAction {
    // The whole dance with the cancellation type might seem pointless. After
    // all, why not use a Bool instead?
    //
    // The goal is to have a simple to use API, but one that allows
    // cancellation. So you could do something as simple as:
    //
    //     DispatchDelayedAction(delay: 5) { doSomething() }
    //
    // Any of the Timer-based approaches would require keeping a reference to
    // self, and even then, the cleaner block-based approach is iOS 10 only.
    //
    // For a GCD-based approach, we can just store a canceled flag and prevent
    // the action from happening. But this would require doing some non-obvious
    // weak self dance as well. We'd want to capture self weakly, and only
    // perform the action if self?.canceled is false or self is nil.
    //
    // The alternative is to capture a class that contains the cancellation
    // status instead of self. If we want to keep a reference to self and cancel
    // that's fine, if we don't the asyncAfter block will capture the
    // cancellation class instance and release it after it completes.

    /// Performs an action after the given delay, unless it's canceled
    ///
    init(delay: DispatchTimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [cancellation] in
            guard !(cancellation.canceled) else {
                return
            }
            action()
        }
    }

    /// Cancels the action if it hasn't been invoked yet
    ///
    func cancel() {
        cancellation.canceled = true
    }

    private let cancellation = Cancellation(false)

    private class Cancellation {
        var canceled: Bool
        init(_ canceled: Bool) {
            self.canceled = canceled
        }
    }
}

/// A helper struct that encapsulates an IncrementalDelay and DispatchDelayedAction, keeping track of current retryAttempt.
///
struct DelayStateWrapper {
    let actionBlock: () -> Void

    var delayCounter: IncrementalDelay<Int>
    var retryAttempt: Int
    var delayedRetryAction: DispatchDelayedAction

    init(delaySequence: [Int], actionBlock: @escaping () -> Void) {
        self.delayCounter = IncrementalDelay(delaySequence)
        self.actionBlock = actionBlock
        self.retryAttempt = 0
        self.delayedRetryAction = DispatchDelayedAction(delay: .seconds(delayCounter.current), action: actionBlock)
    }

    mutating func increment() {
        delayCounter.increment()
        delayedRetryAction.cancel()

        retryAttempt += 1
        delayedRetryAction = DispatchDelayedAction(delay: .seconds(delayCounter.current), action: actionBlock)
    }
}
