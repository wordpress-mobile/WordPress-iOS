import Foundation
import Testing
import WordPressAPIInternal
@testable import WordPress

@MainActor
struct CustomPostListAnalyticsTests {
    @Test func countsOnlyPresentedInstancesOnce() {
        var events: [WPAnalyticsEvent] = []
        let analytics = CustomPostListAnalytics { event, _ in events.append(event) }
        #expect(events.isEmpty)
        analytics.opened(properties: [:])
        analytics.opened(properties: [:])
        #expect(events == [.cptPostListOpened])
    }

    @Test(arguments: [
        (UInt64(0), UInt64(0), "success"),
        (20, 0, "success"),
        (20, 5, "partial_failure"),
        (20, 20, "failure")
    ])
    func detailOutcomes(attempted: UInt64, failed: UInt64, outcome: String) {
        var load = CustomPostListAnalytics.Load(properties: [:], currentPage: nil)
        load.record(.init(totalItems: 20, fetchedCount: attempted, failedCount: failed))
        let properties = load.finishedProperties(isCancelled: false)
        #expect(properties["outcome"] as? String == outcome)
        #expect(properties["fetched_count"] as? UInt64 == attempted - failed)
        #expect(properties["counts_complete"] as? Bool == true)
    }

    @Test(arguments: [
        (nil as UInt32?, false, "initial"),
        (nil, true, "initial"),
        (1, false, "refresh"),
        (3, false, "refresh"),
        (1, true, "pagination"),
        (3, true, "pagination")
    ])
    func loadKindUsesStartingPageAndOperation(currentPage: UInt32?, isLoadingMore: Bool, expected: String) {
        var load = CustomPostListAnalytics.Load(properties: [:], currentPage: currentPage, isLoadingMore: isLoadingMore)
        // A failed request leaves the page unchanged; hierarchy loading can advance it several times.
        load.record(.init(totalItems: 20, fetchedCount: 20, failedCount: 20, currentPage: currentPage))
        load.record(.init(totalItems: 40, fetchedCount: 20, failedCount: 0, currentPage: 4))
        #expect(load.finishedProperties(isCancelled: false)["load_kind"] as? String == expected)
    }

    @Test func aggregatesHierarchyPagesIntoOneEvent() {
        var events: [WPAnalyticsEvent] = []
        var properties: [AnyHashable: Any] = [:]
        let analytics = CustomPostListAnalytics {
            events.append($0)
            properties = $1
        }
        var load = CustomPostListAnalytics.Load(properties: ["tab": "all"], currentPage: 1)
        load.record(.init(totalItems: 20, fetchedCount: 20, failedCount: 5))
        load.record(.init(totalItems: 40, fetchedCount: 10, failedCount: 0))
        analytics.finished(load, isCancelled: false)
        #expect(events == [.cptPostListLoadFinished])
        #expect(properties["attempted_count"] as? UInt64 == 30)
        #expect(properties["fetched_count"] as? UInt64 == 25)
        #expect(properties["failed_count"] as? UInt64 == 5)
        #expect(properties["outcome"] as? String == "partial_failure")
        #expect(properties["load_kind"] as? String == "refresh")
        #expect(properties["tab"] as? String == "all")
        #expect((properties["duration_ms"] as? Double ?? -1) >= 0)
    }

    @Test func thrownFailureAfterPartialProgress() {
        var load = CustomPostListAnalytics.Load(properties: [:], currentPage: 1)
        load.record(.init(totalItems: 20, fetchedCount: 20, failedCount: 0))
        load.error = NSError(domain: "test", code: 1)
        let properties = load.finishedProperties(isCancelled: false)
        #expect(properties["outcome"] as? String == "failure")
        #expect(properties["fetched_count"] as? UInt64 == 20)
        #expect(properties["counts_complete"] as? Bool == false)
    }

    @Test func cancellationTakesPrecedenceOverDetailFailures() {
        var load = CustomPostListAnalytics.Load(properties: [:], currentPage: 1, isLoadingMore: true)
        load.record(.init(totalItems: 20, fetchedCount: 20, failedCount: 5))
        #expect(load.finishedProperties(isCancelled: true)["outcome"] as? String == "cancelled")
        #expect(load.finishedProperties(isCancelled: true)["counts_complete"] as? Bool == false)
        load.error = CancellationError()
        #expect(load.finishedProperties(isCancelled: false)["outcome"] as? String == "cancelled")
        load.error = FetchError.StaleLoadMore
        #expect(load.finishedProperties(isCancelled: false)["outcome"] as? String == "cancelled")
    }
}
