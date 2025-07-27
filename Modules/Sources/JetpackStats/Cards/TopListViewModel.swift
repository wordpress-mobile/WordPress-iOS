import SwiftUI

@MainActor
final class TopListViewModel: ObservableObject, TrafficCardViewModel {
    let items: [TopListItemType]
    let groupedItems: [[TopListItemType]]

    var title: String {
        selection.item.getTitle(for: selection.metric)
    }

    @Published var selection: Selection {
        didSet {
            loadData()
        }
    }
    @Published private(set) var data: TopListChartData?
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: Error?
    @Published private(set) var isStale = false
    @Published private(set) var cachedCountriesMapData: CountriesMapData?

    private let service: any StatsServiceProtocol
    private let fetchLimit: Int
    private let filter: Filter?

    private var loadingTask: Task<Void, Never>?
    private var loadRequestCount = 0
    private var staleTimer: Task<Void, Never>?

    var dateRange: StatsDateRange {
        didSet { loadData() }
    }

    struct Selection: Equatable, Sendable {
        var item: TopListItemType
        var metric: SiteMetric
    }

    enum Filter: Equatable {
        case author(userId: String)
    }

    var isFirstLoad: Bool { isLoading && data == nil }

    private var isFirstAppear = true

    init(
        selection: Selection,
        dateRange: StatsDateRange,
        service: any StatsServiceProtocol,
        items: [TopListItemType]? = nil,
        fetchLimit: Int = 20,
        filter: Filter? = nil,
        initialData: TopListChartData? = nil
    ) {
        self.items = items ?? service.supportedItems
        self.selection = selection
        self.dateRange = dateRange
        self.service = service
        self.fetchLimit = fetchLimit
        self.filter = filter
        self.data = initialData
        self.isLoading = initialData == nil

        self.groupedItems = {
            let primary = service.supportedItems.filter {
                !TopListItemType.secondaryItems.contains($0)
            }
            let secondary = service.supportedItems.filter {
                TopListItemType.secondaryItems.contains($0)
            }
            return [primary, secondary]
        }()
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

            // Cancel stale timer and reset stale flag when data is successfully loaded
            staleTimer?.cancel()
            isStale = false
            self.data = data

            // Update cached CountriesMapData if locations are selected
            if selection.item == .locations {
                updateCountriesMapDataCache(from: data)
            } else {
                cachedCountriesMapData = nil
            }
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
            data = nil
        }

        loadRequestCount = 0
        isLoading = false
    }

    private func getTopListData(for selection: Selection, dateRange: StatsDateRange) async throws -> TopListChartData {
        let granularity = dateRange.dateInterval.preferredGranularity

        // When filter is set for author, we need to fetch authors data
        let fetchItem: TopListItemType
        if let filter, case .author = filter {
            // We have to fake it as "Posts & Pages" does not support filtering
            fetchItem = .authors
        } else {
            fetchItem = selection.item
        }

        // Fetch current data
        async let currentTask = service.getTopListData(
            fetchItem,
            metric: selection.metric,
            interval: dateRange.dateInterval,
            granularity: granularity,
            limit: fetchLimit
        )

        // Fetch previous data only for items that support it
        async let previousTask: TopListData? = {
            guard selection.item != .archive else { return nil }
            return try await service.getTopListData(
                fetchItem,
                metric: selection.metric,
                interval: dateRange.effectiveComparisonInterval,
                granularity: granularity,
                limit: fetchLimit
            )
        }()

        let (current, previous) = try await (currentTask, previousTask)

        let currentItems = filteredItems(current.items)
        let previousItems = filteredItems(previous?.items ?? [])

        // Build previous items dictionary
        var previousItemsDict: [TopListItemID: any TopListItem] = [:]
        for item in previousItems {
            previousItemsDict[item.id] = item
        }

        // Calculate max value from filtered items based on selected metric
        let metric = selection.metric

        return TopListChartData(
            item: selection.item,
            metric: metric,
            items: currentItems,
            previousItems: previousItemsDict
        )
    }

    private func filteredItems(_ items: [any TopListItem]) -> [any TopListItem] {
        guard let filter else {
            return items
        }
        switch filter {
        case .author(let userId):
            let authors = items.lazy.compactMap { $0 as? TopListData.Author }
            if let author = authors.first(where: { $0.userId == userId }),
               let posts = author.posts {
                return posts
            }
            return []
        }
    }

    private func updateCountriesMapDataCache(from data: TopListChartData) {
        let locations = data.items.compactMap { $0 as? TopListData.Location }
        let previousLocations = data.previousItems.compactMapValues { $0 as? TopListData.Location }

        cachedCountriesMapData = CountriesMapData(
            metric: selection.metric,
            locations: locations,
            previousLocations: previousLocations
        )
    }
 }
