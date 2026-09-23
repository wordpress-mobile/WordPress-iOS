import Foundation
import WordPressAPIInternal
import WordPressShared

@MainActor
final class CustomPostListAnalytics {
    private let track: (WPAnalyticsEvent, [AnyHashable: Any]) -> Void
    private var hasTrackedOpened = false

    init(track: @escaping (WPAnalyticsEvent, [AnyHashable: Any]) -> Void = { WPAnalytics.track($0, properties: $1) }) {
        self.track = track
    }

    func opened(properties: [AnyHashable: Any]) {
        // Tabs create their models eagerly. Count only the first presentation,
        // matching the lifetime used by the Sentry detail-failure report.
        guard !hasTrackedOpened else { return }
        hasTrackedOpened = true
        track(.cptPostListOpened, properties)
    }

    func finished(_ load: Load, isCancelled: Bool) {
        track(.cptPostListLoadFinished, load.finishedProperties(isCancelled: isCancelled))
    }

    struct Load {
        var properties: [AnyHashable: Any]
        var error: Error?
        private let started = ContinuousClock.now
        private var attemptedCount: UInt64 = 0
        private var failedCount: UInt64 = 0

        init(properties: [AnyHashable: Any], currentPage: UInt32?, isLoadingMore: Bool = false) {
            self.properties = properties
            self.properties["load_kind"] = currentPage == nil ? "initial" : (isLoadingMore ? "pagination" : "refresh")
            self.properties["loading_strategy"] = "paginated"
        }

        mutating func record(_ result: SyncResult) {
            // Rust's fetchedCount includes failed attempts.
            attemptedCount += result.fetchedCount
            failedCount += result.failedCount
        }

        func finishedProperties(isCancelled: Bool) -> [AnyHashable: Any] {
            var properties = properties
            let elapsed = started.duration(to: .now).components
            properties["duration_ms"] = Double(elapsed.seconds) * 1000 + Double(elapsed.attoseconds) / 1e15
            properties["attempted_count"] = attemptedCount
            properties["fetched_count"] = attemptedCount - failedCount
            properties["failed_count"] = failedCount
            // A thrown or cancelled operation may not return its detail counts.
            properties["counts_complete"] = error == nil && !isCancelled
            if isCancelled || error is CancellationError || (error as? FetchError) == .StaleLoadMore {
                properties["outcome"] = "cancelled"
            } else if error != nil || (failedCount > 0 && failedCount == attemptedCount) {
                properties["outcome"] = "failure"
            } else {
                properties["outcome"] = failedCount > 0 ? "partial_failure" : "success"
            }
            return properties
        }
    }
}
