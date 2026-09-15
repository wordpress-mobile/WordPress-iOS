import Foundation
import Testing

@testable import WordPress

@Suite("CustomPostMetricsStore")
@MainActor
struct CustomPostMetricsStoreTests {
    /// Called from concurrent tasks, so it locks around its bookkeeping.
    private final class ViewFetcher: CustomPostViewCountFetching, @unchecked Sendable {
        private let lock = NSLock()
        var counts: [Int64: Int] = [:]
        private(set) var requested: [Int64] = []
        private var inFlight = 0
        private(set) var peakInFlight = 0
        var delay: Duration = .zero

        func fetchViewCount(postID: Int64) async throws -> Int {
            lock.withLock {
                requested.append(postID)
                inFlight += 1
                peakInFlight = max(peakInFlight, inFlight)
            }
            defer { lock.withLock { inFlight -= 1 } }
            try await Task.sleep(for: delay)
            guard let count = counts[postID] else { throw URLError(.badServerResponse) }
            return count
        }
    }

    private final class CommentRecorder: @unchecked Sendable {
        var batches: [[Int64]] = []
        var counts: [Int64: Int] = [:]
        var fails = false

        func fetcher() -> CustomPostCommentCountFetcher {
            CustomPostCommentCountFetcher { params in
                self.batches.append(params.post)
                if self.fails { throw URLError(.notConnectedToInternet) }
                return .init(
                    postIDs: params.post.flatMap { id in Array(repeating: id, count: self.counts[id] ?? 0) },
                    total: nil
                )
            }
        }
    }

    private func makeStore(
        comments: CommentRecorder? = CommentRecorder(),
        views: ViewFetcher? = ViewFetcher(),
        maxConcurrentViewRequests: Int = 4
    ) -> CustomPostMetricsStore {
        CustomPostMetricsStore(
            commentFetcher: comments?.fetcher(),
            viewFetcher: views,
            debounce: .zero,
            maxConcurrentViewRequests: maxConcurrentViewRequests
        )
    }

    /// Lets the debounce task run, then waits for the fetches it started.
    private func settle(_ store: CustomPostMetricsStore) async {
        for _ in 0..<5 {
            await Task.yield()
        }
        await store.awaitInFlightFetches()
    }

    @Test("visible rows go pending, then loaded")
    func loads() async {
        let comments = CommentRecorder()
        comments.counts = [1: 3]
        let views = ViewFetcher()
        views.counts = [1: 120, 2: 7]
        let store = makeStore(comments: comments, views: views)

        store.rowDidAppear(1)
        store.rowDidAppear(2)
        await settle(store)

        #expect(store.metrics(for: 1) == CustomPostRowMetrics(viewCount: .loaded(120), commentCount: .loaded(3)))
        #expect(store.metrics(for: 2) == CustomPostRowMetrics(viewCount: .loaded(7), commentCount: .loaded(0)))
        #expect(comments.batches == [[1, 2]])
    }

    @Test("a failure clears the skeleton rather than pinning it")
    func failure() async {
        let comments = CommentRecorder()
        comments.fails = true
        let store = makeStore(comments: comments, views: ViewFetcher())

        store.rowDidAppear(1)
        await settle(store)

        #expect(store.metrics(for: 1) == CustomPostRowMetrics(viewCount: .failed, commentCount: .failed))
        #expect(store.metrics(for: 1).isPending == false)
    }

    @Test("a metric with no fetcher is not expected at all")
    func missingFetcher() async {
        let store = makeStore(views: nil)
        store.rowDidAppear(1)
        await settle(store)

        #expect(store.metrics(for: 1).viewCount == nil)
        #expect(store.metrics(for: 1).commentCount == .loaded(0))
    }

    @Test("a disabled store fetches nothing, and re-enabling asks for the visible rows")
    func disabled() async {
        let comments = CommentRecorder()
        let store = makeStore(comments: comments, views: ViewFetcher())
        store.isEnabled = false

        store.rowDidAppear(1)
        await settle(store)
        #expect(comments.batches.isEmpty)
        #expect(store.metrics(for: 1) == CustomPostRowMetrics(viewCount: nil, commentCount: nil))

        store.isEnabled = true
        await settle(store)
        #expect(comments.batches == [[1]])
    }

    @Test("rows already fetched or in flight are not requested again")
    func noDuplicates() async {
        let comments = CommentRecorder()
        let store = makeStore(comments: comments, views: ViewFetcher())

        store.rowDidAppear(1)
        await settle(store)
        store.rowDidDisappear(1)
        store.rowDidAppear(1)
        store.rowDidAppear(2)
        await settle(store)

        #expect(comments.batches == [[1], [2]])
    }

    @Test("retrying failures drops only the failed entries")
    func retryFailures() async {
        let comments = CommentRecorder()
        comments.fails = true
        let views = ViewFetcher()
        views.counts = [1: 5]
        let store = makeStore(comments: comments, views: views)

        store.rowDidAppear(1)
        await settle(store)
        #expect(store.metrics(for: 1) == CustomPostRowMetrics(viewCount: .loaded(5), commentCount: .failed))

        comments.fails = false
        comments.counts = [1: 2]
        store.retryFailures()
        await settle(store)

        #expect(store.metrics(for: 1) == CustomPostRowMetrics(viewCount: .loaded(5), commentCount: .loaded(2)))
        #expect(views.requested == [1])
    }

    @Test("view requests are capped at the configured concurrency")
    func concurrencyCap() async {
        let views = ViewFetcher()
        views.delay = .milliseconds(20)
        views.counts = Dictionary(uniqueKeysWithValues: (1...10).map { ($0, Int($0)) })
        let store = makeStore(comments: nil, views: views, maxConcurrentViewRequests: 3)

        for id in Int64(1)...10 {
            store.rowDidAppear(id)
        }
        await settle(store)

        #expect(views.requested.count == 10)
        #expect(views.peakInFlight <= 3)
        #expect(store.metrics(for: 10).viewCount == .loaded(10))
    }

    @Test("rows scrolled past before their turn are skipped")
    func skipsRowsNoLongerVisible() async {
        let views = ViewFetcher()
        views.delay = .milliseconds(20)
        views.counts = [1: 1, 2: 2, 3: 3]
        let store = makeStore(comments: nil, views: views, maxConcurrentViewRequests: 1)

        store.rowDidAppear(1)
        store.rowDidAppear(2)
        store.rowDidAppear(3)
        await Task.yield()
        await Task.yield()
        store.rowDidDisappear(2)
        await settle(store)

        #expect(views.requested == [1, 3])
        #expect(store.metrics(for: 2).viewCount == nil)
    }
}
