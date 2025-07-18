import SwiftUI

@MainActor
final class TopListCardViewModel: ObservableObject {
    @Published var matchedData: TopListChartData?
    @Published var isLoading = true
    @Published var loadingError: Error?
    @Published var isStale = false

    private let service: any StatsServiceProtocol

    private var loadingTask: Task<Void, Never>?
    private var loadRequestCount = 0
    private var staleTimer: Task<Void, Never>?

    var isFirstLoad: Bool { isLoading && matchedData == nil }

    init(service: any StatsServiceProtocol) {
        self.service = service
    }

    func loadData(for item: TopListItemType, dateRange: StatsDateRange, metric: SiteMetric) {
        loadingTask?.cancel()
        staleTimer?.cancel()

        // Increment request count to track if this is the first request
        loadRequestCount += 1
        let isFirstRequest = loadRequestCount == 1

        // If we have data, start a timer to mark data as stale if there is
        // no response in more than T seconds.
        if matchedData != nil {
            staleTimer = Task { [weak self] in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.isStale = true
            }
        }

        // Create a new loading task
        loadingTask = Task { [weak self] in
            guard let self else { return }

            // Add delay for subsequent requests to avoid rapid API calls when
            // the user quickly switches between data types or metrics.
            if !isFirstRequest {
                try? await Task.sleep(for: .milliseconds(250))
            }

            guard !Task.isCancelled else { return }
            self.selectedMetric = metric
            await self.actuallyLoadData(for: item, dateRange: dateRange, metric: metric)
        }
    }

    private func actuallyLoadData(for item: TopListItemType, dateRange: StatsDateRange, metric: SiteMetric) async {
        isLoading = true
        loadingError = nil

        do {
            try Task.checkCancellation()

            let data = try await getTopListData(for: item, dateRange: dateRange)

            // Check for cancellation before updating the state
            try Task.checkCancellation()

            // Cancel stale timer and reset stale flag when data is successfully loaded
            staleTimer?.cancel()
            isStale = false

            matchedData = data
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
            matchedData = nil
        }

        loadRequestCount = 0
        isLoading = false
    }

    private func getTopListData(for item: TopListItemType, dateRange: StatsDateRange) async throws -> TopListChartData {
        let granularity = dateRange.dateInterval.preferredGranularity

        // Fetch both current and previous period data concurrently
        async let currentTask = service.getTopListData(
            item,
            range: dateRange.dateInterval,
            granularity: granularity
        )
        async let previousTask = service.getTopListData(
            item,
            range: dateRange.effectiveComparisonInterval,
            granularity: granularity
        )

        let (current, previous) = try await (currentTask, previousTask)

        // Match current items with their previous counterparts
        let matchedItems = current.items.map { currentItem in
            let previousItem = previous.items.first { $0.id == currentItem.id }
            return TopListChartData.Item(current: currentItem, previous: previousItem)
        }

        // Calculate max value from current items based on selected metric
        let metric = selectedMetric ?? .views
        let maxValue = current.items
            .compactMap { $0.metrics[metric] }
            .max() ?? 1

        return TopListChartData(item: item, metric: metric, items: matchedItems, maxValue: maxValue)
    }

    var maxValue: Int {
        matchedData?.maxValue ?? 1
    }

    private var selectedMetric: SiteMetric?

    func setSelectedMetric(_ metric: SiteMetric) {
        selectedMetric = metric
    }
}
