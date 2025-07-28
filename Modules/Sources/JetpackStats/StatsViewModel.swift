import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject, CardConfigurationDelegate {
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
            .chart(ChartCardConfiguration(metrics: availableMetrics)),
            .topList(TopListCardConfiguration(item: .postsAndPages, metric: .views)),
            .topList(TopListCardConfiguration(item: .referrers, metric: .views)),
            .topList(TopListCardConfiguration(item: .locations, metric: .views))
        ])
    }
    
    private func makeDefaultConfiguration() -> TrafficCardConfiguration {
        Self.makeDefaultConfiguration(context: context)
    }

    private func configureTrafficViewModels() {
        cards = trafficCardConfiguration.cards.compactMap { card in
            createViewModel(for: card)
        }
    }
    
    private func createViewModel(for card: TrafficCardConfiguration.Card) -> TrafficCardViewModel? {
        let viewModel: TrafficCardViewModel?
        
        switch card {
        case .chart(let configuration):
            viewModel = ChartCardViewModel(
                configuration: configuration,
                dateRange: dateRange,
                service: context.service
            )
        case .topList(let configuration):
            viewModel = TopListViewModel(
                configuration: configuration,
                dateRange: dateRange,
                service: context.service
            )
        }
        
        viewModel?.configurationDelegate = self
        return viewModel
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
        let configuration = ChartCardConfiguration(metrics: metrics)
        let card = TrafficCardConfiguration.Card.chart(configuration)
        trafficCardConfiguration.cards.append(card)
        
        // Create and append the view model using shared logic
        if let viewModel = createViewModel(for: card) {
            cards.append(viewModel)
        }
        
        saveConfiguration()
    }
    
    func addTopList(item: TopListItemType, metric: SiteMetric) {
        let configuration = TopListCardConfiguration(item: item, metric: metric)
        let card = TrafficCardConfiguration.Card.topList(configuration)
        trafficCardConfiguration.cards.append(card)
        
        // Create and append the view model using shared logic
        if let viewModel = createViewModel(for: card) {
            cards.append(viewModel)
        }
        
        saveConfiguration()
    }
    
    // MARK: - CardConfigurationDelegate
    
    func saveConfiguration(for card: any TrafficCardViewModel) {
        // Find the index of the card in configuration
        guard let index = trafficCardConfiguration.cards.firstIndex(where: { $0.id == card.id }) else { return }
        
        // Update the configuration based on the card type
        switch card {
        case let chartViewModel as ChartCardViewModel:
            trafficCardConfiguration.cards[index] = .chart(chartViewModel.configuration)
        case let topListViewModel as TopListViewModel:
            trafficCardConfiguration.cards[index] = .topList(topListViewModel.configuration)
        default:
            assertionFailure("Unknown card type")
        }
        
        saveConfiguration()
    }
    
    func deleteCard(_ card: any TrafficCardViewModel) {
        // Find and remove the card from configuration using the protocol's id property
        trafficCardConfiguration.cards.removeAll { $0.id == card.id }
        
        // Remove the card from the view models array
        cards.removeAll { $0.id == card.id }
        
        saveConfiguration()
    }
}
