import Foundation

/// Based on code by Daniele Margutti — http://www.danielemargutti.com (http://www.danielemargutti.com)
/// and Ignazio Calò: http://danielemargutti.com/2017/10/19/throttle-in-swift/
///
/// This class provides an easy way to ensure that an operation won't happen more than once in the specified
/// amount of seconds.
/// A common use case is when performing an online search, to limit the number of requests made to the backend as well
/// as the number of (possibly stale) UI updates as the user types.
///
/// Note:
/// Any new block passed to `throttle(:_)` cancels the previous one. If you need to throttle multiple things
/// (i.e. online search and unrelated background refresh), you'll need to have a separate `Throttle` for each of them.
///
public class Throttle {
    private let queue: DispatchQueue = DispatchQueue.global(qos: .default)
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Double

    init(seconds: Double) {
        self.maxInterval = seconds
    }

    func throttle(callbackQueue: DispatchQueue = DispatchQueue.main, block: @escaping () -> ()) {
        configureJob(callbackQueue: callbackQueue, block: block)

        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }

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
}

private extension Date {
    static func second(from referenceDate: Date) -> Double {
        return Date().timeIntervalSince(referenceDate).rounded()
    }
}
