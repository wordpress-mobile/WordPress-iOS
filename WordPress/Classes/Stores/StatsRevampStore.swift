import Foundation
import WordPressFlux

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
    case refreshTotalLikes(date: Date)
}

enum StatsRevampStoreQuery {

}

class StatsRevampStore: QueryStore<StatsRevampStoreState, StatsRevampStoreQuery> {
    private typealias PeriodOperation = StatsPeriodAsyncOperation
    var statsServiceRemote: StatsServiceRemoteV2?

    private var operationQueue = OperationQueue()
    private let scheduler = Scheduler(seconds: 0.3)

    override init(initialState: StatsRevampStoreState = StatsRevampStoreState(), dispatcher: ActionDispatcher = .global) {
        super.init(initialState: initialState, dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? StatsRevampStoreAction else {
            return
        }

        switch action {
        case .refreshTotalLikes(let date):
            fetchTotalLikesData(date: date)
        case .refreshViewsAndVisitors(let date):
            fetchViewsAndVisitorsData(date: date)
        }
    }
}

// MARK: - Data for Views & Visitors weekly details

private extension StatsRevampStore {
    func shouldFetchViewsAndVisitors() -> Bool {
        return [state.summaryStatus,
                state.topReferrersStatus,
                state.topCountriesStatus].first { $0 == .loading } == nil
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
                DDLogError("Stats Period: Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching referrers.")

            DispatchQueue.main.async {
                self?.receivedReferrers(referrers, error)
            }
        }

        let topCountries = PeriodOperation(service: service, for: .week, date: date, limit: 0) { [weak self] (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching countries.")

            DispatchQueue.main.async {
                self?.receivedCountries(countries, error)
            }
        }

        operationQueue.addOperations([topReferrers,
                                      topCountries],
                                     waitUntilFinished: false)
    }

    private func loadViewsAndVisitorsCache(date: Date) {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
                return
        }

        let summary = StatsRecord.timeIntervalData(for: blog, type: .blogVisitsSummary, period: StatsRecordPeriodType(remoteStatus: .day), date: date)
        let referrers = StatsRecord.timeIntervalData(for: blog, type: .referrers, period: StatsRecordPeriodType(remoteStatus: .week), date: date)
        let countries = StatsRecord.timeIntervalData(for: blog, type: .countryViews, period: StatsRecordPeriodType(remoteStatus: .week), date: date)

        DDLogInfo("Stats Period: Finished loading Period data from Core Data.")

        transaction { state in
            state.summary = summary.flatMap { StatsSummaryTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topReferrers = referrers.flatMap { StatsTopReferrersTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topCountries = countries.flatMap { StatsTopCountryTimeIntervalData(statsRecordValues: $0.recordValues) }
            DDLogInfo("Stats Period: Finished setting data to Period store from Core Data.")
        }
    }
}

// MARK: - Data Total Likes weekly details

private extension StatsRevampStore {
    func shouldFetchTotalLikes() -> Bool {
        return [state.summaryStatus,
                state.topPostsAndPagesStatus].first { $0 == .loading } == nil
    }

    func setTotalLikesDetailsFetchingStatus(_ status: StoreFetchingStatus) {
        if FeatureFlag.statsPerformanceImprovements.enabled {
            transaction { state in
                state.summaryStatus = status
                state.topPostsAndPagesStatus = status
            }
        } else {
            state.summaryStatus = status
            state.topPostsAndPagesStatus = status
        }
    }

    func fetchTotalLikesData(date: Date) {
        loadTotalLikesCache(date: date)

        guard shouldFetchTotalLikes() else {
            DDLogInfo("Stats Views and Visitors details refresh triggered while one was in progress.")
            return
        }

        setTotalLikesDetailsFetchingStatus(.loading)

        fetchSummary(date: date) { [weak self] in
            self?.fetchTotalLikesDetailsData(date: date)
        }
    }

    func fetchTotalLikesDetailsData(date: Date) {
        guard let service = statsRemote() else {
            return
        }

        let topPostsOperation = PeriodOperation(service: service, for: .week, date: date) { [weak self] (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching posts.")

            DispatchQueue.main.async {
                self?.receivedPostsAndPages(posts, error)
            }
        }

        operationQueue.addOperations([topPostsOperation],
                                     waitUntilFinished: false)
    }

    private func loadTotalLikesCache(date: Date) {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
                return
        }

        let summary = StatsRecord.timeIntervalData(for: blog, type: .blogVisitsSummary, period: StatsRecordPeriodType(remoteStatus: .day), date: date)
        let posts = StatsRecord.timeIntervalData(for: blog, type: .topViewedPost, period: StatsRecordPeriodType(remoteStatus: .week), date: date)

        DDLogInfo("Stats Period: Finished loading Period data from Core Data.")

        transaction { state in
            state.summary = summary.flatMap { StatsSummaryTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topPostsAndPages = posts.flatMap { StatsTopPostsTimeIntervalData(statsRecordValues: $0.recordValues) }
            DDLogInfo("Stats Period: Finished setting data to Period store from Core Data.")
        }
    }
}

private extension StatsRevampStore {
    func fetchSummary(date: Date, _ completion: @escaping () -> ()) {
        guard let service = statsRemote() else {
            return
        }

        scheduler.debounce { [weak self] in
            DDLogInfo("Stats Period: Cancel all operations")

            self?.operationQueue.cancelAllOperations()

            let chartOperation = PeriodOperation(service: service, for: .day, date: date, limit: 14) { [weak self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in
                if error != nil {
                    DDLogError("Stats Period: Error fetching summary: \(String(describing: error?.localizedDescription))")
                }

                DDLogInfo("Stats Period: Finished fetching summary.")

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
    }

    func receivedCountries(_ countries: StatsTopCountryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topCountriesStatus = error != nil ? .error : .success

            if countries != nil {
                state.topCountries = countries
            }
        }
    }

    func receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topPostsAndPagesStatus = error != nil ? .error : .success

            if postsAndPages != nil {
                state.topPostsAndPages = postsAndPages
            }
        }
    }

    func receivedSummary(_ summaryData: StatsSummaryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.summaryStatus = error != nil ? .error : .success

            if summaryData != nil {
                state.summary = summaryData
            }
        }
    }
}
