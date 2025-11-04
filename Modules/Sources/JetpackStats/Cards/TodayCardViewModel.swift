import SwiftUI

@MainActor
final class TodayCardViewModel: ObservableObject, TrafficCardViewModel {
    var id: UUID { configuration.id }
    let cardType: CardType = .today

    @Published private(set) var configuration: TodayCardConfiguration
    @Published private(set) var data: TodayCardData?
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: Error?
    @Published var isEditing = false

    let isEditable = false

    weak var configurationDelegate: CardConfigurationDelegate?

    var dateRange: StatsDateRange {
        didSet {
            loadData(for: dateRange.updating(preset: .today))
        }
    }

    var isFirstLoad: Bool { isLoading && data == nil }

    private let service: any StatsServiceProtocol
    let tracker: (any StatsTracker)?

    private var loadingTask: Task<Void, Never>?
    private var isFirstAppear = true

    init(
        configuration: TodayCardConfiguration,
        dateRange: StatsDateRange,
        context: StatsContext,
    ) {
        self.configuration = configuration
        self.dateRange = dateRange.updating(preset: .today)
        self.service = context.service
        self.tracker = context.tracker
    }

    func updateConfiguration(_ newConfiguration: TodayCardConfiguration) {
        self.configuration = newConfiguration
        configurationDelegate?.saveConfiguration(for: self)
        loadData(for: dateRange)
    }

    func onAppear() {
        guard isFirstAppear else { return }
        isFirstAppear = false

        tracker?.send(.cardShown, properties: [
            "card_type": CardType.today.rawValue,
            "configuration": configuration.metrics.map(\.analyticsName).joined(separator: "_")
        ])

        loadData(for: dateRange)
    }

    private func loadData(for dateRange: StatsDateRange) {
        loadingTask?.cancel()

        // Create a new loading task
        loadingTask = Task { [weak self] in
            guard let self else { return }
            await self.actuallyLoadData(dateRange: dateRange)
        }
    }

    private func actuallyLoadData(dateRange: StatsDateRange) async {
        isLoading = true
        loadingError = nil

        do {
            let loadedData = try await getSiteStats(dateRange: dateRange)

            try Task.checkCancellation()

            data = loadedData
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
            tracker?.trackError(error, screen: "today_card")
        }

        isLoading = false
    }

    private func getSiteStats(dateRange: StatsDateRange) async throws -> TodayCardData {
        let granularity = dateRange.dateInterval.preferredGranularity

        async let currentResponseTask = service.getSiteStats(
            interval: dateRange.dateInterval,
            granularity: granularity
        )
        async let previousResponseTask = service.getSiteStats(
            interval: dateRange.effectiveComparisonInterval,
            granularity: granularity
        )

        let currentResponse = try await currentResponseTask
        let previousResponse = try? await previousResponseTask

        // Extract hourly views data and convert to simple tuples
        let calendar = dateRange.calendar
        let hourlyViews = (currentResponse.metrics[.views] ?? []).map { dataPoint in
            (hour: calendar.component(.hour, from: dataPoint.date), value: dataPoint.value)
        }
        let previousHourlyViews = previousResponse?.metrics[.views]?.map { dataPoint in
            (hour: calendar.component(.hour, from: dataPoint.date), value: dataPoint.value)
        }

        var metricsSet = SiteMetricsSet()
        for metric in configuration.metrics {
            metricsSet[metric] = currentResponse.total[metric]
        }

        return TodayCardData(
            hourlyViews: hourlyViews,
            previousHourlyViews: previousHourlyViews,
            metrics: metricsSet
        )
    }
}

struct TodayCardData {
    let id = UUID()
    let hourlyViews: [(hour: Int, value: Int)]
    let previousHourlyViews: [(hour: Int, value: Int)]?
    let metrics: SiteMetricsSet
}
