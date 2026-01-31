import SwiftUI

/// ViewModel managing state and interactions for the WordAds chart card.
@MainActor
final class WordAdsChartCardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var chartData: [WordAdsMetric: SimpleChartData] = [:]
    @Published private(set) var isFirstLoad = true
    @Published private(set) var isLoading = false
    @Published private(set) var loadingError: Error?

    @Published var selectedMetric: WordAdsMetric = .impressions
    @Published var selectedGranularity: DateRangeGranularity = .day
    @Published var currentDate = Date()
    @Published var selectedBarDate: Date?

    // MARK: - Dependencies

    private let service: any StatsServiceProtocol
    private var loadTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var tabViewData: [MetricsOverviewTabView<WordAdsMetric>.MetricData] {
        WordAdsMetric.allMetrics.map { metric in
            let data = chartData[metric]
            let value: Int? = {
                guard let selectedBarDate else {
                    return data?.currentTotal
                }
                // Find the data point matching the selected date
                return data?.currentData.first { dataPoint in
                    Calendar.current.isDate(
                        dataPoint.date,
                        equalTo: selectedBarDate,
                        toGranularity: selectedGranularity.component
                    )
                }?.value
            }()

            return MetricsOverviewTabView.MetricData(
                metric: metric,
                value: value,
                previousValue: nil // No comparison for legacy chart
            )
        }
    }

    var formattedCurrentDate: String {
        let formatter = StatsDateFormatter()
        let dateToFormat = selectedBarDate ?? currentDate
        return formatter.formatDate(dateToFormat, granularity: selectedGranularity, context: .regular)
    }

    var currentChartData: SimpleChartData? {
        chartData[selectedMetric]
    }

    var placeholderTabViewData: [MetricsOverviewTabView<WordAdsMetric>.MetricData] {
        WordAdsMetric.allMetrics.map { metric in
            .init(metric: metric, value: 12345, previousValue: nil)
        }
    }

    // MARK: - Initialization

    init(service: any StatsServiceProtocol) {
        self.service = service
    }

    // MARK: - Public Methods

    func onAppear() {
        guard chartData.isEmpty else { return }
        loadData()
    }

    func onGranularityChanged(_ newGranularity: DateRangeGranularity) {
        selectedGranularity = newGranularity
        currentDate = Date() // Reset to current date
        selectedBarDate = nil
        loadData()
    }

    func onBarTapped(_ date: Date) {
        selectedBarDate = date
    }

    func onMetricSelected(_ metric: WordAdsMetric) {
        selectedMetric = metric
        // Chart data already loaded, no need to reload
        // Select the latest period for the new metric
        if let latestDate = chartData[metric]?.currentData.last?.date {
            selectedBarDate = latestDate
        }
    }

    // MARK: - Private Methods

    func loadData() {
        // Cancel any existing load task
        loadTask?.cancel()

        withAnimation {
            isLoading = true
            loadingError = nil
        }

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await service.getWordAdsStats(
                    date: currentDate,
                    granularity: selectedGranularity
                )

                guard !Task.isCancelled else { return }

                // Transform response into chart data for each metric
                var newChartData: [WordAdsMetric: SimpleChartData] = [:]
                for metric in WordAdsMetric.allMetrics {
                    if let dataPoints = response.metrics[metric] {
                        let total = DataPoint.getTotalValue(
                            for: dataPoints,
                            metric: metric
                        ) ?? 0

                        newChartData[metric] = SimpleChartData(
                            metric: metric,
                            granularity: selectedGranularity,
                            currentTotal: total,
                            currentData: dataPoints
                        )
                    }
                }

                withAnimation {
                    self.chartData = newChartData
                    self.isFirstLoad = false
                    self.isLoading = false
                }

                // Automatically select the latest period if no selection exists
                if self.selectedBarDate == nil, let latestDate = newChartData[self.selectedMetric]?.currentData.last?.date {
                    self.selectedBarDate = latestDate
                }
            } catch {
                guard !Task.isCancelled else { return }
                withAnimation {
                    self.loadingError = error
                    self.isFirstLoad = false
                    self.isLoading = false
                }
            }
        }
    }
}
