import Foundation

/// Based on code by Daniele Margutti — http://www.danielemargutti.com (http://www.danielemargutti.com)
/// and Ignazio Calò: http://danielemargutti.com/2017/10/19/throttle-in-swift/
///
/// This class provides an easy way to ensure that an operation won't happen more than once in the specified
/// amount of seconds.
/// A common use case is when performing an online search, to limit the number of requests made to the backend as well
/// as the number of (possibly stale) UI updates as the user types.
///
/// There are two different algorithms to achieve this: Throttle and Debounce. Both are implemented as a separate function in this class.
///
public class Scheduler {
    private let queue: DispatchQueue = DispatchQueue.global(qos: .default)
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Double

    init(seconds: Double) {
        self.maxInterval = seconds
    }

    /// The original function be called the very first time this function is called, and, at most, once per specified period.
    ///
    func throttle(callbackQueue: DispatchQueue = DispatchQueue.main, block: @escaping () -> ()) {
        configureJob(callbackQueue: callbackQueue, block: block)

        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }


    /// The original function will be called after the caller stops calling the this function after the specified period.
    ///
    func debounce(callbackQueue: DispatchQueue = DispatchQueue.main, block: @escaping () -> ()) {
        configureJob(callbackQueue: callbackQueue, block: block)
        queue.asyncAfter(deadline: .now() + maxInterval, execute: job)
    }

    private func configureJob(callbackQueue: DispatchQueue = DispatchQueue.main, block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem() { [weak self] in
            self?.previousRun = Date()
            callbackQueue.async {
                block()
            }
        }
    }

    /// Cancels the current scheduled job, if any.
    ///
    func cancel() {
        job.cancel()
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Double {
        return Date().timeIntervalSince(referenceDate).rounded()
    }
}
