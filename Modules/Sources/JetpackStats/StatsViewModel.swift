import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var trafficCardConfiguration: TrafficCardConfiguration
    @Published var dateRange: StatsDateRange {
        didSet {
            updateViewModelsDateRange()
        }
    }
    @Published private(set) var cards: [any TrafficCardViewModel] = []

    let context: StatsContext
    private let userDefaults: UserDefaults
    private let configurationKey = "JetpackStatsTrafficConfiguration"

    init(context: StatsContext, initialDateRange: StatsDateRange, userDefaults: UserDefaults = .standard) {
        self.context = context
        self.dateRange = initialDateRange
        self.userDefaults = userDefaults
        self.trafficCardConfiguration = Self.loadConfiguration(
            from: userDefaults,
            key: configurationKey,
            context: context
        )
        configureTrafficViewModels()
    }

    func saveConfiguration() {
        guard let data = try? JSONEncoder().encode(trafficCardConfiguration) else { return }
        userDefaults.set(data, forKey: configurationKey)
    }

    func resetToDefault() {
        trafficCardConfiguration = makeDefaultConfiguration()
        userDefaults.removeObject(forKey: configurationKey)
    }

    private static func loadConfiguration(from userDefaults: UserDefaults, key: String, context: StatsContext) -> TrafficCardConfiguration {
        guard let data = userDefaults.data(forKey: key),
              let configuration = try? JSONDecoder().decode(TrafficCardConfiguration.self, from: data) else {
            return makeDefaultConfiguration(context: context)
        }
        return configuration
    }
    
    private static func makeDefaultConfiguration(context: StatsContext) -> TrafficCardConfiguration {
        // Get available metrics from service, excluding downloads
        let availableMetrics = context.service.supportedMetrics
        
        return TrafficCardConfiguration(cards: [
            .chart(TrafficCardConfiguration.ChartParameters(metrics: availableMetrics)),
            .topList(TrafficCardConfiguration.TopListParameters(item: .postsAndPages, metric: .views)),
            .topList(TrafficCardConfiguration.TopListParameters(item: .referrers, metric: .views)),
            .topList(TrafficCardConfiguration.TopListParameters(item: .locations, metric: .views))
        ])
    }
    
    private func makeDefaultConfiguration() -> TrafficCardConfiguration {
        Self.makeDefaultConfiguration(context: context)
    }

    private func configureTrafficViewModels() {
        cards = trafficCardConfiguration.cards.compactMap { card in
            switch card {
            case .chart(let parameters):
                return ChartCardViewModel(
                    metrics: parameters.metrics,
                    dateRange: dateRange,
                    service: context.service
                )
            case .topList(let parameters):
                return TopListViewModel(
                    selection: .init(item: parameters.item, metric: parameters.metric),
                    dateRange: dateRange,
                    service: context.service
                )
            }
        }
    }

    private func updateViewModelsDateRange() {
        for card in cards {
            card.dateRange = dateRange
        }
    }
    
    // MARK: - Adding Cards
    
    func addChart() {
        // Add chart with default metrics
        let defaultMetrics = context.service.supportedMetrics.filter { $0 != .downloads }
        addChartWithMetrics(defaultMetrics)
    }
    
    func addChartWithMetrics(_ metrics: [SiteMetric]) {
        let parameters = TrafficCardConfiguration.ChartParameters(metrics: metrics)
        trafficCardConfiguration.cards.append(.chart(parameters))
        saveConfiguration()
        configureTrafficViewModels()
    }
    
    func addTopList(item: TopListItemType, metric: SiteMetric) {
        let parameters = TrafficCardConfiguration.TopListParameters(item: item, metric: metric)
        trafficCardConfiguration.cards.append(.topList(parameters))
        saveConfiguration()
        configureTrafficViewModels()
    }
    
    // MARK: - Deleting Cards
    
    func deleteCard(_ cardViewModel: TrafficCardViewModel) {
        guard let index = cards.firstIndex(where: { $0.id == cardViewModel.id }) else { return }
        
        trafficCardConfiguration.cards.remove(at: index)
        saveConfiguration()
        configureTrafficViewModels()
    }
}
