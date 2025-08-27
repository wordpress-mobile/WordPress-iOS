import SwiftUI
import Combine
import UIKit

@MainActor
final class StatsViewModel: ObservableObject, CardConfigurationDelegate {
    @Published var trafficCardConfiguration: TrafficCardConfiguration

    @Published var dateRange: StatsDateRange {
        didSet {
            updateViewModelsDateRange()
            saveSelectedDateRangePreset()
            if !dateRange.isAdjacent(to: oldValue) {
                clearNavigationStack()
            }
        }
    }

    private var isNavigationStackLocked = false
    @Published private(set) var cards: [any TrafficCardViewModel] = []
    @Published private(set) var dateRangeNavigationStack: [StatsDateRange] = []

    let scrollToCardSubject = PassthroughSubject<UUID, Never>()

    let context: StatsContext

    private let userDefaults: UserDefaults
    private let configurationKey = "JetpackStatsTrafficConfiguration"
    private let dateRangePresetKey = "JetpackStatsSelectedDateRangePreset"

    init(context: StatsContext, userDefaults: UserDefaults = .standard) {
        self.context = context
        self.userDefaults = userDefaults

        // Try to load the saved preset, otherwise use the initial date range
        if let savedPreset = Self.loadDateRangePreset(from: userDefaults, key: dateRangePresetKey) {
            self.dateRange = context.calendar.makeDateRange(for: savedPreset)
        } else {
            self.dateRange = context.calendar.makeDateRange(for: .last7Days)
        }

        self.trafficCardConfiguration = Self.loadConfiguration(
            from: userDefaults,
            key: configurationKey,
            context: context
        )
        configureCards()
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

        var cards: [TrafficCardConfiguration.Card] = [
            .chart(ChartCardConfiguration(metrics: availableMetrics))
        ]

        if UIDevice.current.userInterfaceIdiom == .pad { // Has more space
            cards += [
                .topList(TopListCardConfiguration(item: .postsAndPages, metric: .views)),
                .topList(TopListCardConfiguration(item: .referrers, metric: .views)),
                .topList(TopListCardConfiguration(item: .searchTerms, metric: .views)),
                .topList(TopListCardConfiguration(item: .locations, metric: .views)),
                .topList(TopListCardConfiguration(item: .externalLinks, metric: .views)),
                .topList(TopListCardConfiguration(item: .authors, metric: .views)),
            ]
        } else {
            cards += [
                .topList(TopListCardConfiguration(item: .postsAndPages, metric: .views)),
                .topList(TopListCardConfiguration(item: .referrers, metric: .views)),
                .topList(TopListCardConfiguration(item: .locations, metric: .views))
            ]
        }

        return TrafficCardConfiguration(cards: cards)
    }

    private func makeDefaultConfiguration() -> TrafficCardConfiguration {
        Self.makeDefaultConfiguration(context: context)
    }

    private func configureCards() {
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
                service: context.service,
                tracker: context.tracker
            )
        case .topList(let configuration):
            viewModel = TopListViewModel(
                configuration: configuration,
                dateRange: dateRange,
                service: context.service,
                tracker: context.tracker
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

    // MARK: - Date Range Navigation

    /// Navigates to a new date range with drill-down, pushing current range to stack
    func pushDateRange(_ newDateRange: StatsDateRange) {
        isNavigationStackLocked = true
        dateRangeNavigationStack.append(dateRange)
        dateRange = newDateRange
        isNavigationStackLocked = false
    }

    /// Pops the previous date range from the navigation stack
    func popDateRange() {
        guard let previousRange = dateRangeNavigationStack.popLast() else {
            return
        }
        isNavigationStackLocked = true
        dateRange = previousRange
        isNavigationStackLocked = false
    }

    /// Clears the navigation stack
    private func clearNavigationStack() {
        guard !isNavigationStackLocked else { return }
        dateRangeNavigationStack.removeAll()
    }

    // MARK: - Adding Cards

    func addCard(type: AddCardType) {
        let card = makeCard(type: type)
        trafficCardConfiguration.cards.append(card)
        saveConfiguration()

        // Track card added event
        context.tracker?.send(.cardAdded, properties: ["card_type": cardType(for: card)])

        // Create and append the view model
        if let viewModel = createViewModel(for: card) {
            cards.append(viewModel)

            // Enable editing after a short delay to allow the card to be added and scrolled to
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                scrollToCardSubject.send(viewModel.id)
                try? await Task.sleep(for: .milliseconds(500))
                viewModel.isEditing = true
            }
        }
    }

    private func makeCard(type: AddCardType) -> TrafficCardConfiguration.Card {
        switch type {
        case .chart:
            let configuration = ChartCardConfiguration(metrics: context.service.supportedMetrics)
            return TrafficCardConfiguration.Card.chart(configuration)
        case .topList:
            let configuration = TopListCardConfiguration(item: .postsAndPages, metric: .views)
            return TrafficCardConfiguration.Card.topList(configuration)
        }
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
        // Track card removed event
        context.tracker?.send(.cardRemoved, properties: ["card_type": cardType(for: card)])

        // Find and remove the card from configuration using the protocol's id property
        trafficCardConfiguration.cards.removeAll { $0.id == card.id }

        // Remove the card from the view models array
        cards.removeAll { $0.id == card.id }

        saveConfiguration()
    }

    func moveCard(_ card: any TrafficCardViewModel, direction: MoveDirection) {
        // Find the index of the card in both arrays
        guard let currentIndex = cards.firstIndex(where: { $0.id == card.id }),
              let configIndex = trafficCardConfiguration.cards.firstIndex(where: { $0.id == card.id }) else {
            return
        }

        let newIndex: Int
        switch direction {
        case .up:
            newIndex = max(0, currentIndex - 1)
        case .down:
            newIndex = min(cards.count - 1, currentIndex + 1)
        case .top:
            newIndex = 0
        case .bottom:
            newIndex = cards.count - 1
        }

        // If the position hasn't changed, return early
        if newIndex == currentIndex {
            return
        }

        // Move in cards array
        let movedCard = cards.remove(at: currentIndex)
        cards.insert(movedCard, at: newIndex)

        // Move in configuration array
        let movedConfigCard = trafficCardConfiguration.cards.remove(at: configIndex)
        trafficCardConfiguration.cards.insert(movedConfigCard, at: newIndex)

        saveConfiguration()

        // Scroll to the moved card after a short delay
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            scrollToCardSubject.send(card.id)
        }
    }

    // MARK: - Date Range Persistence

    private func saveSelectedDateRangePreset() {
        if let preset = dateRange.preset {
            userDefaults.set(preset.rawValue, forKey: dateRangePresetKey)
        } else {
            userDefaults.removeObject(forKey: dateRangePresetKey)
        }
    }

    private static func loadDateRangePreset(from userDefaults: UserDefaults, key: String) -> DateIntervalPreset? {
        guard let rawValue = userDefaults.string(forKey: key),
              let preset = DateIntervalPreset(rawValue: rawValue) else {
            return nil
        }
        return preset
    }

    // MARK: - Reset Settings

    /// Resets all persistently stored settings including card configuration and date range preset
    func resetAllSettings() {
        // Reset card configuration
        resetToDefault()

        // Reset date range preset
        userDefaults.removeObject(forKey: dateRangePresetKey)

        // Reset date range to default
        dateRange = context.calendar.makeDateRange(for: .last7Days)
    }

    // MARK: - Helper Methods

    private func cardType(for card: TrafficCardConfiguration.Card) -> String {
        switch card {
        case .chart: return "chart"
        case .topList: return "top_list"
        }
    }

    private func cardType(for viewModel: any TrafficCardViewModel) -> String {
        switch viewModel {
        case is ChartCardViewModel: return "chart"
        case is TopListViewModel: return "top_list"
        default: return "unknown"
        }
    }
}
