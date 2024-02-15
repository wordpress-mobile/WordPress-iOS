import Foundation
import WordPressFlux

/// StatsRevampStore is created to support use cases in Stats that can combine
/// different periods and endpoints.
///
/// The class hides the complexity and exposes actions and data for specific use cases.

struct StatsRevampStoreState {
    var summary: StatsSummaryTimeIntervalData?
    var summaryStatus: StoreFetchingStatus = .idle

    var topReferrers: StatsTopReferrersTimeIntervalData?
    var topReferrersStatus: StoreFetchingStatus = .idle

    var topCountries: StatsTopCountryTimeIntervalData?
    var topCountriesStatus: StoreFetchingStatus = .idle

    var topPostsAndPages: StatsTopPostsTimeIntervalData?
    var topPostsAndPagesStatus: StoreFetchingStatus = .idle
}

enum StatsRevampStoreAction: Action {
    case refreshViewsAndVisitors(date: Date)
    case refreshLikesTotals(date: Date)
}

enum StatsRevampStoreQuery {}

class StatsRevampStore: QueryStore<StatsRevampStoreState, StatsRevampStoreQuery> {
    private typealias PeriodOperation = StatsPeriodAsyncOperation
    private var statsServiceRemote: StatsServiceRemoteV2?

    private var operationQueue = OperationQueue()
    private let scheduler = Scheduler(seconds: 0.3)
    private let cache: StatsPediodCache = .shared

    // MARK: - Query Store

    override init(initialState: StatsRevampStoreState = StatsRevampStoreState(), dispatcher: ActionDispatcher = .global) {
        super.init(initialState: initialState, dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? StatsRevampStoreAction else {
            return
        }

        switch action {
        case .refreshLikesTotals(let date):
            fetchLikesTotalsData(date: date)
        case .refreshViewsAndVisitors(let date):
            fetchViewsAndVisitorsData(date: date)
        }
    }
}

// MARK: - Status

extension StatsRevampStore {
    var viewsAndVisitorsStatus: StoreFetchingStatus {
        let statuses = [state.summaryStatus, state.topReferrersStatus, state.topCountriesStatus]
        return aggregateStatus(for: statuses, data: state.summary)
    }

    var likesTotalsStatus: StoreFetchingStatus {
        let statuses = [state.summaryStatus, state.topPostsAndPagesStatus]
        return aggregateStatus(for: statuses, data: state.summary)
    }
}

// MARK: - Getters

extension StatsRevampStore {
    struct ViewsAndVisitorsData {
        let summary: StatsSummaryTimeIntervalData?
        let topReferrers: StatsTopReferrersTimeIntervalData?
        let topCountries: StatsTopCountryTimeIntervalData?
    }

    struct TotalLikesData {
        let summary: StatsSummaryTimeIntervalData?
        let topPostsAndPages: StatsTopPostsTimeIntervalData?
    }

    func getViewsAndVisitorsData() -> StatsRevampStore.ViewsAndVisitorsData {
        return ViewsAndVisitorsData(
            summary: state.summary,
            topReferrers: state.topReferrers,
            topCountries: state.topCountries
        )
    }

    func getLikesTotalsData() -> StatsRevampStore.TotalLikesData {
        return TotalLikesData(
            summary: state.summary,
            topPostsAndPages: state.topPostsAndPages
        )
    }
}

// MARK: - Helpers

private extension StatsRevampStore {
    func aggregateStatus(for statuses: [StoreFetchingStatus], data: Any?) -> StoreFetchingStatus {
        if statuses.first(where: { $0 == .loading }) != nil {
            return .loading
        } else if statuses.first(where: { $0 == .success }) != nil || data != nil {
            return .success
        } else if statuses.first(where: { $0 == .error }) != nil {
            return .error
        } else {
            return .idle
        }
    }
}

// MARK: - Data for Views & Visitors weekly details

private extension StatsRevampStore {
    func shouldFetchViewsAndVisitors() -> Bool {
        return viewsAndVisitorsStatus != .loading
    }

    func setViewsAndVisitorsFetchingStatus(_ status: StoreFetchingStatus) {
        transaction { state in
            state.summaryStatus = status
            state.topReferrersStatus = status
            state.topCountriesStatus = status
        }
    }

    func fetchViewsAndVisitorsData(date: Date) {
        loadViewsAndVisitorsCache(date: date)

        guard shouldFetchViewsAndVisitors() else {
            DDLogInfo("Stats Views and Visitors details refresh triggered while one was in progress.")
            return
        }

        setViewsAndVisitorsFetchingStatus(.loading)

        fetchSummary(date: date) { [weak self] in
            self?.fetchViewsAndVisitorsDetailsData(date: date)
        }
    }

    func fetchViewsAndVisitorsDetailsData(date: Date) {
        guard let service = statsRemote() else {
            return
        }

        let topReferrers = PeriodOperation(service: service, for: .week, date: date) { [weak self] (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Revamp Store: Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Revamp Store: Finished fetching referrers.")

            DispatchQueue.main.async {
                self?.receivedReferrers(referrers, error)
            }
        }

        let topCountries = PeriodOperation(service: service, for: .week, date: date, limit: 0) { [weak self] (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Revamp Store: Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Revamp Store: Finished fetching countries.")

            DispatchQueue.main.async {
                self?.receivedCountries(countries, error)
            }
        }

        operationQueue.addOperations([topReferrers,
                                      topCountries],
                                     waitUntilFinished: false)
    }

    private func loadViewsAndVisitorsCache(date: Date) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func getValue<T: StatsTimeIntervalData>(_ record: StatsPediodCache.Record, period: StatsPeriodUnit) -> T? {
            cache.getValue(record: record, date: date, period: period, unit: period, siteID: siteID)
        }
        transaction { state in
            state.summary = getValue(.timeIntervalsSummary, period: .day)
            state.topReferrers = getValue(.topReferrers, period: .week)
            state.topCountries = getValue(.topCountries, period: .week)
            DDLogInfo("Stats Revamp Store: Finished setting data to Period store from cache")
        }
    }
}

// MARK: - Data Total Likes weekly details

private extension StatsRevampStore {
    func shouldFetchLikesTotals() -> Bool {
        return likesTotalsStatus != .loading
    }

    func setLikesTotalsDetailsFetchingStatus(_ status: StoreFetchingStatus) {
        transaction { state in
            state.summaryStatus = status
            state.topPostsAndPagesStatus = status
        }
    }

    func fetchLikesTotalsData(date: Date) {
        loadLikesTotalsCache(date: date)

        guard shouldFetchLikesTotals() else {
            DDLogInfo("Stats Views and Visitors details refresh triggered while one was in progress.")
            return
        }

        setLikesTotalsDetailsFetchingStatus(.loading)

        fetchSummary(date: date) { [weak self] in
            self?.fetchLikesTotalsDetailsData(date: date)
        }
    }

    func fetchLikesTotalsDetailsData(date: Date) {
        guard let service = statsRemote() else {
            return
        }

        let topPostsOperation = PeriodOperation(service: service, for: .week, date: date) { [weak self] (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Revamp Store: Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Revamp Store: Finished fetching posts.")

            DispatchQueue.main.async {
                self?.receivedPostsAndPages(posts, error)
            }
        }

        operationQueue.addOperations([topPostsOperation],
                                     waitUntilFinished: false)
    }

    private func loadLikesTotalsCache(date: Date) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func getValue<T: StatsTimeIntervalData>(_ record: StatsPediodCache.Record, period: StatsPeriodUnit) -> T? {
            cache.getValue(record: record, date: date, period: period, unit: period, siteID: siteID)
        }
        transaction { state in
            state.summary = getValue(.timeIntervalsSummary, period: .day)
            state.topPostsAndPages = getValue(.topPostsAndPages, period: .week)
            DDLogInfo("Stats Revamp Store: Finished setting data to Period store from cache.")
        }
    }
}

private extension StatsRevampStore {
    func fetchSummary(date: Date, _ completion: @escaping () -> ()) {
        guard let service = statsRemote() else {
            return
        }

        scheduler.debounce { [weak self] in
            DDLogInfo("Stats Revamp Store: Cancel all operations")

            self?.operationQueue.cancelAllOperations()

            let chartOperation = PeriodOperation(service: service, for: .day, date: date, limit: 14) { [weak self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in
                if error != nil {
                    DDLogError("Stats Revamp Store: Error fetching summary: \(String(describing: error?.localizedDescription))")
                }

                DDLogInfo("Stats Revamp Store: Finished fetching summary.")

                DispatchQueue.main.async {
                    self?.receivedSummary(summary, error)
                    completion()
                }
            }

            self?.operationQueue.addOperation(chartOperation)
        }
    }
}

// MARK: - Helpers
private extension StatsRevampStore {
    func statsRemote() -> StatsServiceRemoteV2? {
        // initialize the service if it's nil
        guard let statsService = statsServiceRemote else {
            initializeStatsRemote()
            return statsServiceRemote
        }
        // also re-initialize the service if the site has changed
        if let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue, siteID != statsService.siteID {
            initializeStatsRemote()
        }
        return statsServiceRemote
    }

    func initializeStatsRemote() {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
            let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone
            else {
                statsServiceRemote = nil
                return
        }

        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        statsServiceRemote = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: timeZone)
    }
}

// MARK: - Receive Data

private extension StatsRevampStore {
    func receivedReferrers(_ referrers: StatsTopReferrersTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topReferrersStatus = error != nil ? .error : .success

            if referrers != nil {
                state.topReferrers = referrers
            }
        }

        persistData(state.topReferrers, record: .topReferrers)
    }

    func receivedCountries(_ countries: StatsTopCountryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topCountriesStatus = error != nil ? .error : .success

            if countries != nil {
                state.topCountries = countries
            }
        }

        persistData(state.topCountries, record: .topCountries)
    }

    func receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topPostsAndPagesStatus = error != nil ? .error : .success

            if postsAndPages != nil {
                state.topPostsAndPages = postsAndPages
            }
        }

        persistData(state.topPostsAndPages, record: .topPostsAndPages)
    }

    func receivedSummary(_ summaryData: StatsSummaryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.summaryStatus = error != nil ? .error : .success

            if summaryData != nil {
                state.summary = summaryData
            }
        }

        persistData(state.summary, record: .timeIntervalsSummary)
    }
}

private extension StatsRevampStore {
    func persistData<T: StatsTimeIntervalData>(_ data: T?, record: StatsPediodCache.Record) {
        guard let data, let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        cache.setValue(data, record: record, siteID: siteID)
    }
}
