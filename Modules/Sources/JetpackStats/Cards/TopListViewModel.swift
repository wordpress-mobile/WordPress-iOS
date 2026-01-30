import SwiftUI

@MainActor
final class TopListViewModel: ObservableObject, TrafficCardViewModel {
    var id: UUID { configuration.id }
    let cardType: CardType = .topList
    let items: [TopListItemType]
    let groupedItems: [[TopListItemType]]

    var title: String {
        selection.item.localizedTitle
    }

    @Published private(set) var configuration: TopListCardConfiguration {
        didSet {
            configurationDelegate?.saveConfiguration(for: self)
            updateSelection()
        }
    }

    @Published var selection: Selection {
        didSet {
            loadData()
        }
    }
    @Published private(set) var data: TopListData?
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: Error?
    @Published private(set) var isStale = false
    @Published private(set) var countriesMapData: CountriesMapData?
    @Published private(set) var pieChartData: PieChartData?

    @Published var isEditing = false

    weak var configurationDelegate: CardConfigurationDelegate?

    let filter: Filter?

    private let service: any StatsServiceProtocol
    let tracker: (any StatsTracker)?
    private let fetchLimit: Int?

    private var loadingTask: Task<Void, Never>?
    private var loadRequestCount = 0
    private var staleTimer: Task<Void, Never>?

    var dateRange: StatsDateRange {
        didSet { loadData() }
    }

    struct Selection: Equatable, Sendable {
        var item: TopListItemType
        var metric: SiteMetric
        var options = TopListItemOptions()
    }

    enum Filter: Equatable {
        case author(userId: String)
        case utmMetric(values: [String])
    }

    var isFirstLoad: Bool { isLoading && data == nil }

    private var isFirstAppear = true

    init(
        configuration: TopListCardConfiguration,
        dateRange: StatsDateRange,
        service: any StatsServiceProtocol,
        tracker: (any StatsTracker)? = nil,
        items: [TopListItemType]? = nil,
        fetchLimit: Int? = 100,
        filter: Filter? = nil,
        initialData: TopListData? = nil
    ) {
        self.configuration = configuration
        self.selection = Selection(item: configuration.item, metric: configuration.metric)
        self.items = items ?? service.supportedItems
        self.dateRange = dateRange
        self.service = service
        self.tracker = tracker
        self.fetchLimit = fetchLimit
        self.filter = filter
        self.data = initialData
        self.isLoading = initialData == nil

        let supportedItems = Set(service.supportedItems)
        self.groupedItems = [
            TopListItemType.contentItems,
            TopListItemType.trafficSourceItems,
            TopListItemType.audienceEngagementItems
        ].map {
            $0.filter(supportedItems.contains)
        }.filter {
            !$0.isEmpty
        }
    }

    func updateConfiguration(_ newConfiguration: TopListCardConfiguration) {
        self.configuration = newConfiguration
    }

    private func updateSelection() {
        selection = Selection(item: configuration.item, metric: configuration.metric)
    }

    func onAppear() {
        guard isFirstAppear else { return }
        isFirstAppear = false

        // Track card shown event
        tracker?.send(.cardShown, properties: [
            "card_type": CardType.topList.rawValue,
            "configuration": "\(selection.item.analyticsName)_\(selection.metric.analyticsName)",
            "item_type": selection.item.analyticsName,
            "metric": selection.metric.analyticsName
        ])

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
        if data != nil {
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

            // Fetch country-level data for map if viewing regions or cities
            var mapData: CountriesMapData?
            if selection.item == .locations {
                if selection.options.locationLevel == .countries {
                    // Use the main data for countries
                    mapData = createCountriesMapData(from: data)
                } else {
                    // Fetch separate country-level data for regions/cities
                    var countriesSelection = selection
                    countriesSelection.options.locationLevel = .countries
                    let countriesData = try await getTopListData(for: countriesSelection, dateRange: dateRange)
                    mapData = createCountriesMapData(from: countriesData)
                }
            }

            // Create pie chart data for devices
            var pieData: PieChartData?
            if selection.item == .devices {
                pieData = PieChartData(items: data.items, metric: selection.metric)
            }

            // Check for cancellation before updating the state
            try Task.checkCancellation()

            // Cancel stale timer and reset stale flag when data is successfully loaded
            staleTimer?.cancel()
            isStale = false

            self.data = data
            self.countriesMapData = mapData
            self.pieChartData = pieData
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
            data = nil
            countriesMapData = nil
            staleTimer?.cancel()
            tracker?.trackError(error, screen: "top_list_card")
        }

        loadRequestCount = 0
        isLoading = false
    }

    private func getTopListData(for selection: Selection, dateRange: StatsDateRange) async throws -> TopListData {
        let granularity = dateRange.dateInterval.preferredGranularity

        // When filter is set, we need to fetch the appropriate data type
        let fetchItem: TopListItemType
        if let filter {
            switch filter {
            case .author:
                // We have to fake it as "Posts & Pages" does not support filtering
                fetchItem = .authors
            case .utmMetric:
                // Fetch UTM data to get posts for specific campaign
                fetchItem = .utm
            }
        } else {
            fetchItem = selection.item
        }

        // Fetch current data
        async let currentTask = service.getTopListData(
            fetchItem,
            metric: selection.metric,
            interval: dateRange.dateInterval,
            granularity: granularity,
            limit: fetchLimit,
            options: selection.options
        )

        // Fetch previous data only for items that support it
        async let previousTask: TopListResponse? = {
            guard selection.item != .archive && dateRange.comparison != .off else {
                return nil
            }
            return try await service.getTopListData(
                fetchItem,
                metric: selection.metric,
                interval: dateRange.effectiveComparisonInterval,
                granularity: granularity,
                limit: fetchLimit,
                options: selection.options
            )
        }()

        let (current, previous) = try await (currentTask, previousTask)

        let currentItems = filteredItems(current.items)
        let previousItems = filteredItems(previous?.items ?? [])

        // Build previous items dictionary
        var previousItemsDict: [TopListItemID: any TopListItemProtocol] = [:]
        for item in previousItems {
            previousItemsDict[item.id] = item
        }

        // Calculate max value from filtered items based on selected metric
        let metric = selection.metric

        return TopListData(
            item: selection.item,
            metric: metric,
            items: currentItems,
            previousItems: previousItemsDict
        )
    }

    private func filteredItems(_ items: [any TopListItemProtocol]) -> [any TopListItemProtocol] {
        guard let filter else {
            return items
        }
        switch filter {
        case .author(let userId):
            let authors = items.lazy.compactMap { $0 as? TopListItem.Author }
            if let author = authors.first(where: { $0.userId == userId }),
               let posts = author.posts {
                return posts
            }
            return []
        case .utmMetric(let values):
            let utmMetrics = items.lazy.compactMap { $0 as? TopListItem.UTMMetric }
            if let metric = utmMetrics.first(where: { $0.values == values }),
               let posts = metric.posts {
                return posts
            }
            return []
        }
    }

    private func createCountriesMapData(from data: TopListData) -> CountriesMapData {
        let locations = data.items.compactMap { $0 as? TopListItem.Location }
        let previousLocations = data.previousItems.compactMapValues { $0 as? TopListItem.Location }

        return CountriesMapData(
            metric: selection.metric,
            locations: locations,
            previousLocations: previousLocations
        )
    }
 }
