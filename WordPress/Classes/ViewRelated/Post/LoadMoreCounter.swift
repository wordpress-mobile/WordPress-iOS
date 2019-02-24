import Foundation

/// Temporary counter to help investigate an old issue with load more analytics being spammed.
/// See https://github.com/wordpress-mobile/WordPress-iOS/issues/6819
class LoadMoreCounter {

    private(set) var count: Int = 0
    private var dryRun = false

    /// Initializer
    ///
    /// Parameters:
    /// - startingCount - Optionally set the starting number for the counter. Default is 0.
    /// - dryRun - pass true to avoid dispatching tracks events.  Useful for testing. Default is false.
    ///
    init(startingCount: Int = 0, dryRun: Bool = false) {
        self.count = startingCount
        self.dryRun = dryRun
    }

    /// Increments the counter.
    /// Returns true if Analytics were bumped. False otherwise.
    ///
    @discardableResult
    func increment(properties: [String: AnyObject]) -> Bool {
        count += 1

        // For thresholds use the following:
        // 1: Baseline.  Confirms we're bumping the stat and lets us roughly calculate uniques.
        // 100: Its unlikely this should happen in a normal session. Bears more investigation.
        // 1000: We should never see this many in a normal session. Something is probably broken.
        // 10000: Ditto
        let benchmarks = [1, 100, 1000, 10000]

        guard benchmarks.contains(count) else {
            return false
        }

        if !dryRun {
            var props = properties
            props["count"] = count as AnyObject
            WPAnalytics.track(.postListExcessiveLoadMoreDetected, withProperties: props)
        }

        return true
    }
}
