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
        self.trafficCardConfiguration = Self.loadConfiguration(from: userDefaults, key: configurationKey)
        configureTrafficViewModels()
    }

    func saveConfiguration() {
        guard let data = try? JSONEncoder().encode(trafficCardConfiguration) else { return }
        userDefaults.set(data, forKey: configurationKey)
    }

    func resetToDefault() {
        trafficCardConfiguration = .defaultConfiguration
        userDefaults.removeObject(forKey: configurationKey)
    }

    private static func loadConfiguration(from userDefaults: UserDefaults, key: String) -> TrafficCardConfiguration {
        guard let data = userDefaults.data(forKey: key),
              let configuration = try? JSONDecoder().decode(TrafficCardConfiguration.self, from: data) else {
            return .defaultConfiguration
        }
        return configuration
    }

    private func configureTrafficViewModels() {
        cards = trafficCardConfiguration.cards.compactMap { card in
            switch card {
            case .chart:
                return ChartCardViewModel(
                    metrics: context.service.supportedMetrics,
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
}
