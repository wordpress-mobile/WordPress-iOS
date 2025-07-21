import SwiftUI

@MainActor
final class TopListCardViewModel: ObservableObject, TrafficCardViewModel {
    let items: [TopListItemType]

    var title: String {
        selection.item.getTitle(for: selection.metric)
    }

    @Published var selection: Selection {
        didSet {
            loadData()
        }
    }
    @Published private(set) var matchedData: TopListChartData?
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: Error?
    @Published private(set) var isStale = false

    private let service: any StatsServiceProtocol

    private var loadingTask: Task<Void, Never>?
    private var loadRequestCount = 0
    private var staleTimer: Task<Void, Never>?

    var dateRange: StatsDateRange {
        didSet { loadData() }
    }

    struct Selection: Equatable {
        var item: TopListItemType
        var metric: SiteMetric
    }

    var isFirstLoad: Bool { isLoading && matchedData == nil }

    private var isFirstAppear = true

    init(selection: Selection, dateRange: StatsDateRange, service: any StatsServiceProtocol) {
        self.items = service.supportedItems
        self.selection = selection
        self.dateRange = dateRange
        self.service = service
    }

    func onAppear() {
        guard isFirstAppear else { return }
        isFirstAppear = false
        loadData()
    }

    private func loadData() {
        loadingTask?.cancel()
        staleTimer?.cancel()

        // Increment request count to track if this is the first request
        loadRequestCount += 1
        let isFirstRequest = loadRequestCount == 1

        // If we have data, start a timer to mark data as stale if there is
        // no response in more than T seconds.
        if matchedData != nil {
            staleTimer = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                self?.isStale = true
            }
        }

        // Create a new loading task
        loadingTask = Task { [selection, dateRange, weak self] in
            guard let self else { return }

            // Add delay for subsequent requests to avoid rapid API calls when
            // the user quickly switches between data types or metrics.
            if !isFirstRequest {
                try? await Task.sleep(for: .milliseconds(250))
            }

            guard !Task.isCancelled else { return }
            await self.actuallyLoadData(for: selection, dateRange: dateRange)
        }
    }

    private func actuallyLoadData(for selection: Selection, dateRange: StatsDateRange) async {
        isLoading = true
        loadingError = nil

        do {
            try Task.checkCancellation()

            let data = try await getTopListData(for: selection, dateRange: dateRange)

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

    private func getTopListData(for selection: Selection, dateRange: StatsDateRange) async throws -> TopListChartData {
        let granularity = dateRange.dateInterval.preferredGranularity

        // Fetch both current and previous period data concurrently
        async let currentTask = service.getTopListData(
            selection.item,
            metric: selection.metric,
            interval: dateRange.dateInterval,
            granularity: granularity
        )
        async let previousTask = service.getTopListData(
            selection.item,
            metric: selection.metric,
            interval: dateRange.effectiveComparisonInterval,
            granularity: granularity
        )

        let (current, previous) = try await (currentTask, previousTask)

        // Match current items with their previous counterparts
        let matchedItems = current.items.map { currentItem in
            let previousItem = previous.items.first { $0.id == currentItem.id }
            return TopListChartData.Item(current: currentItem, previous: previousItem)
        }

        // Calculate max value from current items based on selected metric
        let metric = selection.metric
        let maxValue = current.items
            .compactMap { $0.metrics[metric] }
            .max() ?? 1

        return TopListChartData(item: selection.item, metric: metric, items: matchedItems, maxValue: maxValue)
    }
}
