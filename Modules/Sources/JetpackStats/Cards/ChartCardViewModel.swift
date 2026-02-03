import SwiftUI

@MainActor
final class ChartCardViewModel: ObservableObject, TrafficCardViewModel {
    var id: UUID { configuration.id }
    var metrics: [SiteMetric] { configuration.metrics }
    let cardType: CardType = .chart

    @Published private(set) var configuration: ChartCardConfiguration
    @Published private(set) var chartData: [SiteMetric: ChartData] = [:]
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: Error?
    @Published private(set) var isStale = false

    @Published var isEditing = false
    @Published var selectedMetric: SiteMetric

    @Published var selectedChartType: ChartType {
        didSet {
            // Update configuration when chart type changes
            configuration.chartType = selectedChartType
            configurationDelegate?.saveConfiguration(for: self)
        }
    }

    @Published var selectedGranularity: DateRangeGranularity? {
        didSet {
            // Reload data with new granularity
            loadData(for: dateRange)
        }
    }

    weak var configurationDelegate: CardConfigurationDelegate?

    var dateRange: StatsDateRange {
        didSet {
            // Reset granularity to automatic when date period changes (but not for adjacent navigation)
            if !dateRange.isAdjacent(to: oldValue) {
                selectedGranularity = nil
            }
            loadData(for: dateRange)
        }
    }

    var effectiveGranularity: DateRangeGranularity {
        selectedGranularity ?? dateRange.dateInterval.preferredGranularity
    }

    private let service: any StatsServiceProtocol
    let tracker: (any StatsTracker)?

    private var loadingTask: Task<Void, Never>?
    private var loadRequestCount = 0
    private var staleTimer: Task<Void, Never>?
    private var isFirstAppear = true

    var isFirstLoad: Bool { isLoading && chartData.isEmpty }

    init(
        configuration: ChartCardConfiguration,
        dateRange: StatsDateRange,
        service: any StatsServiceProtocol,
        tracker: (any StatsTracker)? = nil
    ) {
        self.configuration = configuration
        self.selectedMetric = configuration.metrics.first ?? .views
        self.selectedChartType = configuration.chartType
        self.dateRange = dateRange
        self.service = service
        self.tracker = tracker
    }

    func updateConfiguration(_ newConfiguration: ChartCardConfiguration) {
        self.configuration = newConfiguration

        // Update selectedMetric if it's no longer available in the new configuration
        if !newConfiguration.metrics.contains(selectedMetric) {
            selectedMetric = newConfiguration.metrics.first ?? .views
        }

        // Update chart type from configuration (without triggering didSet)
        if selectedChartType != newConfiguration.chartType {
            selectedChartType = newConfiguration.chartType
        }

        configurationDelegate?.saveConfiguration(for: self)
    }

    func onAppear() {
        guard isFirstAppear else { return }
        isFirstAppear = false

        // Track card shown event
        tracker?.send(.cardShown, properties: [
            "card_type": CardType.chart.rawValue,
            "configuration": metrics.map { $0.analyticsName }.joined(separator: "_"),
            "chart_type": selectedChartType.rawValue
        ])

        loadData(for: dateRange)
    }

    private func loadData(for dateRange: StatsDateRange) {
        loadingTask?.cancel()
        staleTimer?.cancel()

        // Increment request count to track if this is the first request
        loadRequestCount += 1
        let isFirstRequest = loadRequestCount == 1

        // If we have data, start a timer to mark data as stale if there is
        // no response in more than T seconds.
        if !chartData.isEmpty {
            staleTimer = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                self?.isStale = true
            }
        }

        // Create a new loading task
        loadingTask = Task { [weak self] in
            guard let self else { return }

            // Add delay for subsequent requests to avoid rapid API calls when
            // the user quickly switches between date intervals.
            if !isFirstRequest {
                try? await Task.sleep(for: .milliseconds(250))
            }

            guard !Task.isCancelled else { return }
            await self.actuallyLoadData(dateRange: dateRange)
        }
    }

    private func actuallyLoadData(dateRange: StatsDateRange) async {
        isLoading = true
        loadingError = nil

        do {
            try Task.checkCancellation()

            let data = try await getSiteStats(dateRange: dateRange)

            // Check for cancellation before updating the state
            try Task.checkCancellation()

            // Cancel stale timer and reset stale flag when data is successfully loaded
            staleTimer?.cancel()
            isStale = false
            chartData = data
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
            tracker?.trackError(error, screen: "chart_card")
        }

        loadRequestCount = 0
        isLoading = false
    }

    private func getSiteStats(dateRange: StatsDateRange) async throws -> [SiteMetric: ChartData] {
        var output: [SiteMetric: ChartData] = [:]

        let granularity = selectedGranularity ?? dateRange.dateInterval.preferredGranularity

        // Fetch both current and previous period data concurrently
        async let currentResponseTask = service.getSiteStats(
            interval: dateRange.dateInterval,
            granularity: granularity
        )
        async let previousResponseTask = service.getSiteStats(
            interval: dateRange.effectiveComparisonInterval,
            granularity: granularity
        )

        let (currentResponse, previousResponse) = try await (currentResponseTask, previousResponseTask)

        for (metric, dataPoints) in currentResponse.metrics {
            let previousDataPoints = previousResponse.metrics[metric] ?? []

            // Map previous data to align with current period dates so they
            // are displayed on the same timeline on the charts.
            let mappedPreviousDataPoints = DataPoint.mapDataPoints(
                currentData: dataPoints,
                previousData: previousDataPoints,
                dateRange: dateRange
            )

            output[metric] = ChartData(
                metric: metric,
                granularity: granularity,
                dateInterval: dateRange.dateInterval,
                currentTotal: currentResponse.total[metric] ?? 0,
                currentData: dataPoints,
                previousTotal: previousResponse.total[metric] ?? 0,
                previousData: previousDataPoints,
                mappedPreviousData: mappedPreviousDataPoints
            )
        }

        return output
    }

    var tabViewData: [MetricsOverviewTabView<SiteMetric>.MetricData] {
        metrics.map { metric in
            if let chartData = chartData[metric] {
                return .init(
                    metric: metric,
                    value: chartData.currentTotal,
                    previousValue: chartData.previousTotal
                )
            } else {
                return .init(metric: metric, value: nil, previousValue: nil)
            }
        }
    }

    var placeholderTabViewData: [MetricsOverviewTabView<SiteMetric>.MetricData] {
        metrics.map { metric in
            .init(metric: metric, value: 12345, previousValue: 11234)
        }
    }
}
