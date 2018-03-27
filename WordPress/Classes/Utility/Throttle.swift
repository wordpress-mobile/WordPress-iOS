import Foundation

// Based on code by Daniele Margutti — http://www.danielemargutti.com (http://www.danielemargutti.com) and Ignazio Calò:
// http://danielemargutti.com/2017/10/19/throttle-in-swift/

/// This class provides an easy way to ensure that an operation won't be repeated more often than `seconds` amount of time.
/// Common use cases include online search — avoiding hitting the backend with a request for every character
/// the user types.

/// - Note:
/// Any new block passed to `throttle(:_)` cancels the previous one. If you need to throttle multiple things
/// (i.e. online search and unrelated background refresh), you'll need to have a separate `Throttle` for each of them.
public class Throttle {
    private let queue: DispatchQueue = DispatchQueue.global(qos: .default)

    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Double

    init(seconds: Double) {
        self.maxInterval = seconds
    }

    func throttle(callbackQueue: DispatchQueue = DispatchQueue.main, block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem(){ [weak self] in
            self?.previousRun = Date()
            callbackQueue.async {
                block()
            }
        }

        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }

}

private extension Date {
    static func second(from referenceDate: Date) -> Double {
        return Date().timeIntervalSince(referenceDate).rounded()
    }
}

