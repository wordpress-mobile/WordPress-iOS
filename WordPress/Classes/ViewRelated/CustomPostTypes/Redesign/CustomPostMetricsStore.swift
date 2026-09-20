import Foundation

enum CustomPostMetricState: Equatable {
    case pending
    case loaded(Int)
    /// The fetch failed or answered with nothing usable. The row shows no
    /// number and stops waiting for one; a refresh retries.
    case failed
}

/// What one row shows in its meta line. `nil` means the metric is not
/// expected at all, e.g. view counts on a site without stats.
struct CustomPostRowMetrics: Equatable {
    var viewCount: CustomPostMetricState?
    var commentCount: CustomPostMetricState?

    var isPending: Bool {
        viewCount == .pending || commentCount == .pending
    }
}

/// Per-row view and comment counts for the redesigned posts list.
///
/// Driven by scroll position rather than by page load because neither source
/// is free: view counts are one request per post, comment counts one per
/// visible batch. Results are cached per post id so scrolling back to a row
/// does not refetch it, and nothing in this path can take the screen down.
@MainActor
final class CustomPostMetricsStore: ObservableObject {
    @Published private(set) var viewCounts: [Int64: CustomPostMetricState] = [:]
    @Published private(set) var commentCounts: [Int64: CustomPostMetricState] = [:]

    /// False while the list is condensed: those rows show no metrics, so
    /// nothing is requested. Re-enabling asks for the rows still on screen.
    var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            if isEnabled {
                scheduleFetch()
            } else {
                // A fetch already waiting out the debounce would otherwise
                // still fire, for rows that no longer show what it asks for.
                debounceTask?.cancel()
                debounceTask = nil
            }
        }
    }

    private let commentFetcher: CustomPostCommentCountFetcher?
    private let viewFetcher: (any CustomPostViewCountFetching)?
    private let debounce: Duration
    private let maxConcurrentViewRequests: Int

    private var visibleIDs: Set<Int64> = []
    private var debounceTask: Task<Void, Never>?
    private var fetchTasks: [UUID: Task<Void, Never>] = [:]

    init(
        commentFetcher: CustomPostCommentCountFetcher?,
        viewFetcher: (any CustomPostViewCountFetching)?,
        debounce: Duration = .milliseconds(300),
        maxConcurrentViewRequests: Int = 4
    ) {
        self.commentFetcher = commentFetcher
        self.viewFetcher = viewFetcher
        self.debounce = debounce
        self.maxConcurrentViewRequests = maxConcurrentViewRequests
    }

    func rowDidAppear(_ id: Int64) {
        visibleIDs.insert(id)
        scheduleFetch()
    }

    func rowDidDisappear(_ id: Int64) {
        visibleIDs.remove(id)
    }

    /// Drops only the "nothing to show" entries so a transient failure is
    /// retried, while numbers already fetched stay put.
    func retryFailures() {
        viewCounts = viewCounts.filter { $0.value != .failed }
        commentCounts = commentCounts.filter { $0.value != .failed }
        scheduleFetch()
    }

    func metrics(for id: Int64) -> CustomPostRowMetrics {
        CustomPostRowMetrics(
            viewCount: viewFetcher == nil ? nil : viewCounts[id],
            commentCount: commentFetcher == nil ? nil : commentCounts[id]
        )
    }

    /// Waits for every fetch started so far. Test support.
    func awaitInFlightFetches() async {
        for task in fetchTasks.values {
            await task.value
        }
    }

    // MARK: - Fetching

    /// A fling changes the visible set on nearly every frame. Without settling
    /// first, each change would start fetching for rows already gone.
    private func scheduleFetch() {
        guard isEnabled else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled, let self else { return }
            fetchVisibleRows()
        }
    }

    private func fetchVisibleRows() {
        let ids = visibleIDs.sorted()
        fetchCommentCounts(for: ids.filter { commentCounts[$0] == nil })
        fetchViewCounts(for: ids.filter { viewCounts[$0] == nil })
    }

    /// One batched request for the visible rows.
    private func fetchCommentCounts(for ids: [Int64]) {
        guard let commentFetcher, !ids.isEmpty else { return }
        for id in ids {
            commentCounts[id] = .pending
        }
        track { [weak self] in
            let counts = (try? await commentFetcher.fetchCommentCounts(for: ids)) ?? [:]
            guard let self else { return }
            for id in ids {
                commentCounts[id] = counts[id].map(CustomPostMetricState.loaded) ?? .failed
            }
        }
    }

    /// The stats API answers for one post at a time, so this runs a few at a
    /// time and merges each row in as soon as it lands.
    private func fetchViewCounts(for ids: [Int64]) {
        guard let viewFetcher, !ids.isEmpty else { return }
        for id in ids {
            viewCounts[id] = .pending
        }
        track { [weak self, maxConcurrentViewRequests] in
            await withTaskGroup(of: (Int64, Int?).self) { group in
                var remaining = ids[...]
                for _ in 0..<maxConcurrentViewRequests {
                    if let id = self?.nextVisibleID(from: &remaining) {
                        group.addTask { (id, try? await viewFetcher.fetchViewCount(postID: id)) }
                    }
                }
                for await (id, count) in group {
                    self?.viewCounts[id] = count.map(CustomPostMetricState.loaded) ?? .failed
                    if let next = self?.nextVisibleID(from: &remaining) {
                        group.addTask { (next, try? await viewFetcher.fetchViewCount(postID: next)) }
                    }
                }
            }
        }
    }

    /// The next id still worth a request. Checked when a slot frees up rather
    /// than when the batch was queued: by then the user may have scrolled well
    /// past the row, and a request for it would be spent on something off
    /// screen. Skipped ids go back to "not fetched" so a later appearance asks again.
    private func nextVisibleID(from remaining: inout ArraySlice<Int64>) -> Int64? {
        while let id = remaining.popFirst() {
            if visibleIDs.contains(id) {
                return id
            }
            viewCounts[id] = nil
        }
        return nil
    }

    private func track(_ operation: @escaping @MainActor () async -> Void) {
        let key = UUID()
        fetchTasks[key] = Task { [weak self] in
            await operation()
            self?.fetchTasks[key] = nil
        }
    }
}
