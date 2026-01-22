import SwiftUI
import Combine
import UIKit

@MainActor
final class StatsViewModel: ObservableObject, CardConfigurationDelegate {
    @Published var trafficCardConfiguration: TrafficCardConfiguration

    @Published var dateRange: StatsDateRange {
        didSet {
            updateViewModelsDateRange()
            if !isNavigationStackLocked {
                saveSelectedDateRangePreset()
                saveSelectedComparisonPeriod()
            }
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
    private static let configurationKey = "JetpackStatsTrafficConfiguration"
    private static let dateRangePresetKey = "JetpackStatsSelectedDateRangePreset"
    private static let comparisonPeriodKey = "JetpackStatsComparisonPeriod"
    private static let versionKey = "JetpackStatsVersionKey"

    init(context: StatsContext, userDefaults: UserDefaults = .standard) {
        self.context = context
        self.userDefaults = userDefaults

        Self.performMigrations(userDefaults: userDefaults, context: context)

        let preset = Self.loadDateRangePreset(from: userDefaults)
        let comparison = Self.loadComparisonPeriod(from: userDefaults)
        self.dateRange = context.calendar.makeDateRange(
            for: preset ?? .last7Days,
            comparison: comparison ?? .precedingPeriod
        )

        let configuraiton = Self.getConfiguration(from: userDefaults)
        self.trafficCardConfiguration = configuraiton ?? Self.makeDefaultConfiguration(context: context)

        configureCards()
    }

    private static func performMigrations(userDefaults: UserDefaults, context: StatsContext) {
        if userDefaults.integer(forKey: Self.versionKey) == 0 {
            userDefaults.set(1, forKey: Self.versionKey)

            if var configuration = Self.getConfiguration(from: userDefaults) {
                let metrics = Set(context.service.supportedMetrics)
                let index = (UIDevice.current.userInterfaceIdiom == .pad && !configuration.cards.isEmpty) ? 1 : 0
                configuration.cards.insert(.today(.init(supportedMetrics: metrics)), at: index)
                Self.saveConfiguration(configuration, in: userDefaults)
            }
        }
    }

    private func saveConfiguration() {
        Self.saveConfiguration(trafficCardConfiguration, in: userDefaults)
    }

    func resetToDefault() {
        trafficCardConfiguration = makeDefaultConfiguration()
        userDefaults.removeObject(forKey: Self.configurationKey)
    }

    private static func saveConfiguration(_ configuration: TrafficCardConfiguration, in userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        userDefaults.set(data, forKey: Self.configurationKey)
    }

    private static func getConfiguration(from userDefaults: UserDefaults) -> TrafficCardConfiguration? {
        guard let data = userDefaults.data(forKey: Self.configurationKey) else { return nil}
        return try? JSONDecoder().decode(TrafficCardConfiguration.self, from: data)
    }

    private static func makeDefaultConfiguration(context: StatsContext) -> TrafficCardConfiguration {
        let availableMetrics = context.service.supportedMetrics

        if UIDevice.current.userInterfaceIdiom == .pad {
            // The iPad vesrion has more space, to it's OK to add more advanced cards.
            return TrafficCardConfiguration(cards: [
                .chart(.init(metrics: availableMetrics)),
                .today(.init(supportedMetrics: Set(availableMetrics))),
                .topList(.init(item: .postsAndPages, metric: .views)),
                .topList(.init(item: .referrers, metric: .views)),
                .topList(.init(item: .searchTerms, metric: .views)),
                .topList(.init(item: .locations, metric: .views)),
                .topList(.init(item: .externalLinks, metric: .views)),
                .topList(.init(item: .authors, metric: .views)),
            ])
        } else {
            return TrafficCardConfiguration(cards: [
                .today(.init(supportedMetrics: Set(availableMetrics))),
                .chart(.init(metrics: availableMetrics)),
                .topList(.init(item: .postsAndPages, metric: .views)),
                .topList(.init(item: .referrers, metric: .views)),
                .topList(.init(item: .locations, metric: .views))
            ])
        }
    }

    private func makeDefaultConfiguration() -> TrafficCardConfiguration {
        Self.makeDefaultConfiguration(context: context)
    }

    private func configureCards() {
        cards = trafficCardConfiguration.cards.map(createViewModel)
    }

    private func createViewModel(for card: TrafficCardConfiguration.Card) -> TrafficCardViewModel {
        let viewModel: TrafficCardViewModel

        switch card {
        case .today(let configuration):
            viewModel = TodayCardViewModel(
                configuration: configuration,
                dateRange: dateRange,
                context: context
            )
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

        viewModel.configurationDelegate = self
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

    func addCard(type: CardType) {
        let card = makeCard(type: type)
        trafficCardConfiguration.cards.append(card)
        saveConfiguration()

        // Track card added event
        context.tracker?.send(.cardAdded, properties: ["card_type": type.rawValue])

        // Create and append the view model
        let viewModel = createViewModel(for: card)
        cards.append(viewModel)

        // Enable editing after a short delay to allow the card to be added and scrolled to
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            scrollToCardSubject.send(viewModel.id)
            try? await Task.sleep(for: .milliseconds(500))
            viewModel.isEditing = true
        }
    }

    private func makeCard(type: CardType) -> TrafficCardConfiguration.Card {
        switch type {
        case .today:
            let supported = Set(context.service.supportedMetrics)
            let metrics = [SiteMetric.views, .visitors, .likes, .comments]
                .filter(supported.contains)
            let configuration = TodayCardConfiguration(metrics: metrics)
            return .today(configuration)
        case .chart:
            let configuration = ChartCardConfiguration(metrics: context.service.supportedMetrics)
            return .chart(configuration)
        case .topList:
            let configuration = TopListCardConfiguration(item: .postsAndPages, metric: .views)
            return .topList(configuration)
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
        context.tracker?.send(.cardRemoved, properties: ["card_type": card.cardType.rawValue])

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

        // Track card movement
        context.tracker?.send(.cardMoved, properties: [
            "card_type": card.cardType.rawValue,
            "action": direction.analyticsName,
            "from_index": String(currentIndex),
            "to_index": String(newIndex)
        ])

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
            userDefaults.set(preset.rawValue, forKey: Self.dateRangePresetKey)
        } else {
            // Do nothing – remember last used preset-based period
        }
    }

    private static func loadDateRangePreset(from userDefaults: UserDefaults) -> DateIntervalPreset? {
        guard let rawValue = userDefaults.string(forKey: Self.dateRangePresetKey),
              let preset = DateIntervalPreset(rawValue: rawValue) else {
            return nil
        }
        return preset
    }

    private func saveSelectedComparisonPeriod() {
        userDefaults.set(dateRange.comparison.rawValue, forKey: Self.comparisonPeriodKey)
    }

    private static func loadComparisonPeriod(from userDefaults: UserDefaults) -> DateRangeComparisonPeriod? {
        guard let rawValue = userDefaults.string(forKey: Self.comparisonPeriodKey),
              let comparisonPeriod = DateRangeComparisonPeriod(rawValue: rawValue) else {
            return nil
        }
        return comparisonPeriod
    }

    // MARK: - Reset Settings

    /// Resets all persistently stored settings including card configuration and date range preset
    func resetAllSettings() {
        // Reset card configuration
        resetToDefault()

        // Reset date range preset
        userDefaults.removeObject(forKey: Self.dateRangePresetKey)

        // Reset comparison period
        userDefaults.removeObject(forKey: Self.comparisonPeriodKey)

        // Reset date range to default
        dateRange = context.calendar.makeDateRange(for: .last7Days)
    }
}
