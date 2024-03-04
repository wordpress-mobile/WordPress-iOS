import Foundation
import WordPressFlux
import WidgetKit

enum PeriodType: CaseIterable {
    case timeIntervalsSummary
    case totalsSummary
    case topPostsAndPages
    case topReferrers
    case topPublished
    case topClicks
    case topAuthors
    case topSearchTerms
    case topCountries
    case topVideos
    case topFileDownloads
}

enum PeriodAction: Action {

    // TODO: Remove together with SiteStatsPeriodViewModelDeprecated
    case refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool)
    case refreshPeriod(query: PeriodQuery)
    case toggleSpam(referrerDomain: String, currentValue: Bool)
}

enum PeriodQuery {
    struct TrafficOverviewParams {
        let date: Date
        let period: StatsPeriodUnit
        let chartBarsUnit: StatsPeriodUnit
        let chartBarsLimit: Int
        let chartTotalsLimit: Int
    }

    case allCachedPeriodData(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit)
    case allPostsAndPages(date: Date, period: StatsPeriodUnit)
    case allSearchTerms(date: Date, period: StatsPeriodUnit)
    case allVideos(date: Date, period: StatsPeriodUnit)
    case allClicks(date: Date, period: StatsPeriodUnit)
    case allAuthors(date: Date, period: StatsPeriodUnit)
    case allReferrers(date: Date, period: StatsPeriodUnit)
    case allCountries(date: Date, period: StatsPeriodUnit)
    case allPublished(date: Date, period: StatsPeriodUnit)
    case allFileDownloads(date: Date, period: StatsPeriodUnit)
    case postStats(postID: Int)
    case trafficOverviewData(TrafficOverviewParams)

    var postID: Int? {
        switch self {
        case .postStats(let postID):
            return postID
        default:
            return nil
        }
    }

    var date: Date {
        switch self {
        case .allCachedPeriodData(let date, _, _):
            return date
        case .allPostsAndPages(let date, _):
            return date
        case .allSearchTerms(let date, _):
            return date
        case .allVideos(let date, _):
            return date
        case .allClicks(let date, _):
            return date
        case .allAuthors(let date, _):
            return date
        case .allReferrers(let date, _):
            return date
        case .allCountries(let date, _):
            return date
        case .allPublished(let date, _):
            return date
        case .allFileDownloads(let date, _):
            return date
        case .trafficOverviewData(let params):
            return params.date
        default:
            return StatsDataHelper.currentDateForSite().normalizedDate()
        }
    }

    var period: StatsPeriodUnit {
        switch self {
        case .allCachedPeriodData( _, let period, _):
            return period
        case .allPostsAndPages( _, let period):
            return period
        case .allSearchTerms( _, let period):
            return period
        case .allVideos( _, let period):
            return period
        case .allClicks( _, let period):
            return period
        case .allAuthors( _, let period):
            return period
        case .allReferrers( _, let period):
            return period
        case .allCountries( _, let period):
            return period
        case .allPublished( _, let period):
            return period
        case .allFileDownloads( _, let period):
            return period
        case .trafficOverviewData(let params):
            return params.period
        default:
            return .day
        }
    }
}

struct PeriodStoreState {

    // Period overview

    var timeIntervalsSummary: StatsSummaryTimeIntervalData? {
        didSet {
            StoreContainer.shared.statsWidgets.updateThisWeekHomeWidget(summary: timeIntervalsSummary)
            storeTodayHomeWidgetData()
        }
    }

    var timeIntervalsSummaryStatus: StoreFetchingStatus = .idle

    var totalsSummary: StatsSummaryTimeIntervalData?
    var totalsSummaryStatus: StoreFetchingStatus = .idle

    var topPostsAndPages: StatsTopPostsTimeIntervalData?
    var topPostsAndPagesStatus: StoreFetchingStatus = .idle

    var topReferrers: StatsTopReferrersTimeIntervalData?
    var topReferrersStatus: StoreFetchingStatus = .idle

    var topClicks: StatsTopClicksTimeIntervalData?
    var topClicksStatus: StoreFetchingStatus = .idle

    var topPublished: StatsPublishedPostsTimeIntervalData?
    var topPublishedStatus: StoreFetchingStatus = .idle

    var topAuthors: StatsTopAuthorsTimeIntervalData?
    var topAuthorsStatus: StoreFetchingStatus = .idle

    var topSearchTerms: StatsSearchTermTimeIntervalData?
    var topSearchTermsStatus: StoreFetchingStatus = .idle

    var topCountries: StatsTopCountryTimeIntervalData?
    var topCountriesStatus: StoreFetchingStatus = .idle

    var topVideos: StatsTopVideosTimeIntervalData?
    var topVideosStatus: StoreFetchingStatus = .idle

    var topFileDownloads: StatsFileDownloadsTimeIntervalData?
    var topFileDownloadsStatus: StoreFetchingStatus = .idle

    // Post Stats

    var postStats = [Int: StatsPostDetails?]()
    var postStatsFetchingStatuses = [Int: StoreFetchingStatus]()
}

protocol StatsPeriodStoreDelegate: AnyObject {
    func didChangeSpamState(for referrerDomain: String, isSpam: Bool)
    func changingSpamStateForReferrerDomainFailed(oldValue: Bool)
}

protocol StatsPeriodStoreMethods {
    var isFetchingSummary: Bool { get }
    var fetchingOverviewHasFailed: Bool { get }
    var containsCachedData: Bool { get }
    var timeIntervalsSummaryStatus: StoreFetchingStatus { get }
    var totalsSummaryStatus: StoreFetchingStatus { get }
    var topPostsAndPagesStatus: StoreFetchingStatus { get }
    var topReferrersStatus: StoreFetchingStatus { get }
    var topPublishedStatus: StoreFetchingStatus { get }
    var topClicksStatus: StoreFetchingStatus { get }
    var topAuthorsStatus: StoreFetchingStatus { get }
    var topSearchTermsStatus: StoreFetchingStatus { get }
    var topCountriesStatus: StoreFetchingStatus { get }
    var topVideosStatus: StoreFetchingStatus { get }
    var topFileDownloadsStatus: StoreFetchingStatus { get }
    func getSummary() -> StatsSummaryTimeIntervalData?
    func getTotalsSummary() -> StatsSummaryTimeIntervalData?
    func getTopReferrers() -> StatsTopReferrersTimeIntervalData?
    func getTopClicks() -> StatsTopClicksTimeIntervalData?
    func getTopAuthors() -> StatsTopAuthorsTimeIntervalData?
    func getTopSearchTerms() -> StatsSearchTermTimeIntervalData?
    func getTopVideos() -> StatsTopVideosTimeIntervalData?
    func getTopCountries() -> StatsTopCountryTimeIntervalData?
    func getTopFileDownloads() -> StatsFileDownloadsTimeIntervalData?
    func getTopPostsAndPages() -> StatsTopPostsTimeIntervalData?
    func getTopPublished() -> StatsPublishedPostsTimeIntervalData?
}

typealias StatsPeriodStoreProtocol = QueryStore<PeriodStoreState, PeriodQuery> & StatsPeriodStoreMethods & StatsStoreCacheable

final class StatsPeriodStore: StatsPeriodStoreProtocol {
    private typealias PeriodOperation = StatsPeriodAsyncOperation
    private typealias PublishedPostOperation = StatsPublishedPostsAsyncOperation
    private typealias PostDetailOperation = StatsPostDetailAsyncOperation

    var statsServiceRemote: StatsServiceRemoteV2?
    private var operationQueue = OperationQueue()
    private let scheduler = Scheduler(seconds: 0.3)
    private let cache: StatsPediodCache = .shared

    weak var delegate: StatsPeriodStoreDelegate?

    init() {
        super.init(initialState: PeriodStoreState())
    }

    override func onDispatch(_ action: Action) {

        guard let periodAction = action as? PeriodAction else {
            return
        }

        switch periodAction {
        case .refreshPeriodOverviewData(let date, let period, let forceRefresh):
            refreshPeriodOverviewData(date: date, period: period, forceRefresh: forceRefresh)
        case .refreshPeriod(let query):
            refreshPeriodData(for: query)
        case .toggleSpam(let referrerDomain, let currentValue):
            toggleSpamState(for: referrerDomain, currentValue: currentValue)
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    private func storeDataInCache() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func setValue<T: StatsTimeIntervalData>(_ value: T, _ record: StatsPediodCache.Record) {
            cache.setValue(value, record: record, siteID: siteID)
        }
        state.timeIntervalsSummary.map { setValue($0, .timeIntervalsSummary) }
        state.totalsSummary.map { setValue($0, .totalsSummary) }
        state.topPostsAndPages.map { setValue($0, .topPostsAndPages) }
        state.topReferrers.map { setValue($0, .topReferrers) }
        state.topClicks.map { setValue($0, .topClicks) }
        state.topPublished.map { setValue($0, .topPublished) }
        state.topAuthors.map { setValue($0, .topAuthors) }
        state.topSearchTerms.map { setValue($0, .topSearchTerms) }
        state.topCountries.map { setValue($0, .topCountries) }
        state.topVideos.map { setValue($0, .topVideos) }
        state.topFileDownloads.map { setValue($0, .topFileDownloads) }
    }
}

// MARK: - Private Methods

private extension StatsPeriodStore {

    // MARK: - Get Data

    private func processQueries() {

        guard !activeQueries.isEmpty else {
            return
        }

        activeQueries.forEach { query in
            refreshPeriodData(for: query)
        }
    }

    private func refreshPeriodData(for query: PeriodQuery) {
        switch query {
        case .allCachedPeriodData(let date, let period, let unit):
            loadFromCache(date: date, period: period, unit: unit)
        case .allPostsAndPages:
            if shouldFetchPostsAndPages() {
                fetchAllPostsAndPages(date: query.date, period: query.period)
            }
        case .allSearchTerms:
            if shouldFetchSearchTerms() {
                fetchAllSearchTerms(date: query.date, period: query.period)
            }
        case .allVideos:
            if shouldFetchVideos() {
                fetchAllVideos(date: query.date, period: query.period)
            }
        case .allClicks:
            if shouldFetchClicks() {
                fetchAllClicks(date: query.date, period: query.period)
            }
        case .allAuthors:
            if shouldFetchAuthors() {
                fetchAllAuthors(date: query.date, period: query.period)
            }
        case .allReferrers:
            if shouldFetchReferrers() {
                fetchAllReferrers(date: query.date, period: query.period)
            }
        case .allCountries:
            if shouldFetchCountries() {
                fetchAllCountries(date: query.date, period: query.period)
            }
        case .allPublished:
            if shouldFetchPublished() {
                fetchAllPublished(date: query.date, period: query.period)
            }
        case .allFileDownloads:
            if shouldFetchFileDownloads() {
                fetchAllFileDownloads(date: query.date, period: query.period)
            }
        case .postStats:
            if shouldFetchPostStats(for: query.postID) {
                fetchPostStats(postID: query.postID)
            }
        case .trafficOverviewData(let params):
            refreshTrafficOverviewData(params)
        }
    }

    private func fetchAsyncData(date: Date, period: StatsPeriodUnit) {
        guard let service = statsRemote() else {
            return
        }

        let group = DispatchGroup()

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching posts.")
        let topPostsOperation = PeriodOperation(service: service, for: period, date: date) { [weak self] (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching posts.")

            DispatchQueue.main.async {
                self?.receivedPostsAndPages(posts, error)
                DDLogInfo("Stats Period: Leave group fetching posts.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching referrers.")
        let topReferrers = PeriodOperation(service: service, for: period, date: date) { [weak self] (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching referrers.")

            DispatchQueue.main.async {
                self?.receivedReferrers(referrers, error)
                DDLogInfo("Stats Period: Leave group fetching referrers.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching published.")
        let topPublished = PublishedPostOperation(service: service, for: period, date: date) { [weak self] (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching published: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching published.")

            DispatchQueue.main.async {
                self?.receivedPublished(published, error)
                DDLogInfo("Stats Period: Leave group fetching published.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching clicks.")
        let topClicks = PeriodOperation(service: service, for: period, date: date) { [weak self] (clicks: StatsTopClicksTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching clicks: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching clicks.")

            DispatchQueue.main.async {
                self?.receivedClicks(clicks, error)
                DDLogInfo("Stats Period: Leave group fetching clicks.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching authors.")
        let topAuthors = PeriodOperation(service: service, for: period, date: date) { [weak self] (authors: StatsTopAuthorsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching authors: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching authors.")

            DispatchQueue.main.async {
                self?.receivedAuthors(authors, error)
                DDLogInfo("Stats Period: Leave group fetching authors.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching search terms.")
        let topSearchTerms = PeriodOperation(service: service, for: period, date: date) { [weak self] (searchTerms: StatsSearchTermTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching search terms: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching search terms.")

            DispatchQueue.main.async {
                self?.receivedSearchTerms(searchTerms, error)
                DDLogInfo("Stats Period: Leave group fetching search terms.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching countries.")
        let topCountries = PeriodOperation(service: service, for: period, date: date, limit: 0) { [weak self] (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching countries.")

            DispatchQueue.main.async {
                self?.receivedCountries(countries, error)
                DDLogInfo("Stats Period: Leave group fetching countries.")
                group.leave()
            }
        }

        group.enter()
        DDLogInfo("Stats Period: Enter group fetching videos.")
        let topVideos = PeriodOperation(service: service, for: period, date: date) { [weak self] (videos: StatsTopVideosTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching videos: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching videos.")

            DispatchQueue.main.async {
                self?.receivedVideos(videos, error)
                DDLogInfo("Stats Period: Leave group fetching videos.")
                group.leave()
            }
        }

        // 'limit' in this context is used for the 'num' parameter for the 'file-downloads' endpoint.
        // 'num' relates to the "number of periods to include in the query".
        group.enter()
        DDLogInfo("Stats Period: Enter group fetching file downloads.")
        let topFileDownloads = PeriodOperation(service: service, for: period, date: date, limit: 1) { [weak self] (downloads: StatsFileDownloadsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error file downloads: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished file downloads.")

            DispatchQueue.main.async {
                self?.receivedFileDownloads(downloads, error)
                DDLogInfo("Stats Period: Leave group fetching file downloads.")
                group.leave()
            }
        }

        operationQueue.addOperations([topPostsOperation,
                                      topReferrers,
                                      topPublished,
                                      topClicks,
                                      topAuthors,
                                      topSearchTerms,
                                      topCountries,
                                      topVideos,
                                      topFileDownloads],
                                     waitUntilFinished: false)

        group.notify(queue: .main) { [weak self] in
            DDLogInfo("Stats Period: Finished fetchAsyncData.")
            self?.storeDataInCache()
        }
    }

    private func loadFromCache(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func getValue<T: StatsTimeIntervalData>(_ record: StatsPediodCache.Record, unit: StatsPeriodUnit? = nil) -> T? {
            cache.getValue(record: record, date: date, period: period, unit: unit, siteID: siteID)
        }
        transaction { state in
            // timeIntervalsSummary and totalsSummary depends on both period and unit
            state.timeIntervalsSummary = getValue(.timeIntervalsSummary, unit: unit)
            // totals are fetched with a unit equal to period
            state.totalsSummary = getValue(.totalsSummary, unit: period)
            state.topPostsAndPages = getValue(.topPostsAndPages)
            state.topReferrers = getValue(.topReferrers)
            state.topClicks = getValue(.topClicks)
            state.topPublished = getValue(.topPublished)
            state.topAuthors = getValue(.topAuthors)
            state.topSearchTerms = getValue(.topSearchTerms)
            state.topCountries = getValue(.topCountries)
            state.topVideos = getValue(.topVideos)
            state.topFileDownloads = getValue(.topFileDownloads)
        }
        DDLogInfo("Stats Period: Finished setting data to Period store from disk cache.")
    }

    // MARK: - Traffic Overview Data

    private func refreshTrafficOverviewData(_ params: PeriodQuery.TrafficOverviewParams) {
        loadFromCache(date: params.date, period: params.period, unit: params.chartBarsUnit)
        cancelQueries()

        setAllFetchingStatus(.loading)
        scheduler.debounce { [weak self] in
            self?.fetchTrafficOverviewChartData(params)
            self?.fetchAsyncData(date: params.date, period: params.period)
        }
    }

    private func fetchTrafficOverviewChartData(_ params: PeriodQuery.TrafficOverviewParams) {
        guard let service = statsRemote() else {
            return
        }

        // Backend doesn't accept a future date when fetching totals in some cases
        // https://github.com/Automattic/jetpack/issues/36117
        let totalsOperationDate = min(params.date, StatsDataHelper.currentDateForSite())

        let totalsOperation = PeriodOperation(service: service, for: params.period, unit: params.period, date: totalsOperationDate, limit: params.chartTotalsLimit) { [weak self] (totalsSummary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Traffic: Error fetching totals summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Traffic: Finished fetching total summary.")

            DispatchQueue.main.async {
                self?.receivedTotalsSummary(totalsSummary, error)
                self?.storeDataInCache()
            }
        }
        operationQueue.addOperation(totalsOperation)

        let chartOperation = PeriodOperation(service: service, for: params.period, unit: params.chartBarsUnit, date: params.date, limit: params.chartBarsLimit) { [weak self] (timeIntervalsSummary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Traffic: Error fetching timeIntervalsSummary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Traffic: Finished fetching timeIntervalsSummary.")

            DispatchQueue.main.async {
                self?.receivedTimeIntervalsSummary(timeIntervalsSummary, error)
                self?.storeDataInCache()
            }
        }

        operationQueue.addOperation(chartOperation)
    }

    // MARK: - Period Overview Data

    private func refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool) {
        if forceRefresh {
            DDLogInfo("Stats Period: Cancel all operations")
            cancelQueries()
            setAllFetchingStatus(.idle)
        }

        loadFromCache(date: date, period: period, unit: period)

        guard shouldFetchOverview() else {
            DDLogInfo("Stats Period Overview refresh triggered while one was in progress.")
            return
        }

        setAllFetchingStatus(.loading)
        scheduler.debounce { [weak self] in
            self?.fetchPeriodOverviewChartData(date: date, period: period, unit: period)
            self?.fetchAsyncData(date: date, period: period)
        }
    }

    private func fetchPeriodOverviewChartData(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit) {
        guard let service = statsRemote() else {
            return
        }

        let chartOperation = PeriodOperation(service: service, for: period, unit: unit, date: date, limit: 14) { [weak self] (timeIntervalsSummary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching timeIntervalsSummary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching timeIntervalsSummary.")

            DispatchQueue.main.async {
                self?.receivedTimeIntervalsSummary(timeIntervalsSummary, error)
                self?.storeDataInCache()
            }
        }

        operationQueue.addOperation(chartOperation)
    }

    // MARK: - Periods

    private func fetchAllPostsAndPages(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topPostsAndPagesStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching posts.")

            DispatchQueue.main.async {
                self?.receivedPostsAndPages(posts, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshPostsAndPages(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPostsAndPages() else {
            DDLogInfo("Stats Period Posts And Pages refresh triggered while one was in progress.")
            return
        }

        fetchAllPostsAndPages(date: date, period: period)
    }

    private func fetchAllSearchTerms(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topSearchTermsStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (searchTerms: StatsSearchTermTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching search terms: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching search terms.")

            DispatchQueue.main.async {
                self?.receivedSearchTerms(searchTerms, error)
            }
            self?.storeDataInCache()
        })
    }

    private func refreshSearchTerms(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchSearchTerms() else {
            DDLogInfo("Stats Period Search Terms refresh triggered while one was in progress.")
            return
        }

        fetchAllSearchTerms(date: date, period: period)
    }

    private func fetchAllVideos(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topVideosStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (videos: StatsTopVideosTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching videos: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching videos.")

            DispatchQueue.main.async {
                self?.receivedVideos(videos, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshVideos(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchVideos() else {
            DDLogInfo("Stats Period Videos refresh triggered while one was in progress.")
            return
        }

        fetchAllVideos(date: date, period: period)
    }

    private func fetchAllClicks(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topClicksStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (clicks: StatsTopClicksTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching clicks: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching clicks.")

            DispatchQueue.main.async {
                self?.receivedClicks(clicks, error)
            }
            self?.storeDataInCache()
        })
    }

    private func refreshClicks(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchClicks() else {
            DDLogInfo("Stats Period Clicks refresh triggered while one was in progress.")
            return
        }

        fetchAllClicks(date: date, period: period)
    }

    private func fetchAllAuthors(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topAuthorsStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (authors: StatsTopAuthorsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching authors: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching authors.")

            DispatchQueue.main.async {
                self?.receivedAuthors(authors, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshAuthors(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchAuthors() else {
            DDLogInfo("Stats Period Authors refresh triggered while one was in progress.")
            return
        }

        fetchAllAuthors(date: date, period: period)
    }

    private func fetchAllReferrers(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topReferrersStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching referrers.")

            DispatchQueue.main.async {
                self?.receivedReferrers(referrers, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshReferrers(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchReferrers() else {
            DDLogInfo("Stats Period Referrers refresh triggered while one was in progress.")
            return
        }

        fetchAllReferrers(date: date, period: period)
    }

    private func fetchAllCountries(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topCountriesStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching countries.")

            DispatchQueue.main.async {
                self?.receivedCountries(countries, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshCountries(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchCountries() else {
            DDLogInfo("Stats Period Countries refresh triggered while one was in progress.")
            return
        }

        fetchAllCountries(date: date, period: period)
    }

    private func fetchAllPublished(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topPublishedStatus = .loading

        operationQueue.addOperation(PublishedPostOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching published: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching published.")

            DispatchQueue.main.async {
                self?.receivedPublished(published, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshPublished(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPublished() else {
            DDLogInfo("Stats Period Published refresh triggered while one was in progress.")
            return
        }

        fetchAllPublished(date: date, period: period)
    }

    private func fetchAllFileDownloads(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        operationQueue.cancelAllOperations()

        state.topFileDownloadsStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 1) { [weak self] (downloads: StatsFileDownloadsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error file downloads: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished file downloads.")

            DispatchQueue.main.async {
                self?.receivedFileDownloads(downloads, error)
                self?.storeDataInCache()
            }
        })
    }

    private func refreshFileDownloads(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchFileDownloads() else {
            DDLogInfo("Stats Period File Downloads refresh triggered while one was in progress.")
            return
        }

        fetchAllFileDownloads(date: date, period: period)
    }

    private func fetchPostStats(postID: Int?) {
        guard
            let postID = postID,
            let statsRemote = statsRemote() else {
                return
        }

        cancelQueries()
        setAllFetchingStatus(.idle)

        state.postStatsFetchingStatuses[postID] = .loading

        operationQueue.addOperation(PostDetailOperation(service: statsRemote, for: postID) { [weak self] (postStats: StatsPostDetails?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching Post Stats: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching post stats.")

            DispatchQueue.main.async {
                self?.receivedPostStats(postStats, postID, error)
            }
        })
    }

    private func refreshPostStats(postID: Int) {
        state.postStatsFetchingStatuses[postID] = .idle
        fetchPostStats(postID: postID)
    }

    // MARK: - Receive data methods

    private func receivedTimeIntervalsSummary(_ timeIntervalsSummaryData: StatsSummaryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.timeIntervalsSummaryStatus = error != nil ? .error : .success

            if timeIntervalsSummaryData != nil {
                state.timeIntervalsSummary = timeIntervalsSummaryData
            }
        }
    }

    private func receivedTotalsSummary(_ summaryData: StatsSummaryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.totalsSummaryStatus = error != nil ? .error : .success

            if summaryData != nil {
                state.totalsSummary = summaryData
            }
        }
    }

    private func receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topPostsAndPagesStatus = error != nil ? .error : .success

            if postsAndPages != nil {
                state.topPostsAndPages = postsAndPages
            }
        }
    }

    private func receivedReferrers(_ referrers: StatsTopReferrersTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topReferrersStatus = error != nil ? .error : .success

            if referrers != nil {
                state.topReferrers = referrers
            }
        }
    }

    private func receivedClicks(_ clicks: StatsTopClicksTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topClicksStatus = error != nil ? .error : .success

            if clicks != nil {
                state.topClicks = clicks
            }
        }
    }

    private func receivedAuthors(_ authors: StatsTopAuthorsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topAuthorsStatus = error != nil ? .error : .success

            if authors != nil {
                state.topAuthors = authors
            }
        }
    }

    private func receivedPublished(_ published: StatsPublishedPostsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topPublishedStatus = error != nil ? .error : .success

            if published != nil {
                state.topPublished = published
            }
        }
    }

    private func receivedSearchTerms(_ searchTerms: StatsSearchTermTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topSearchTermsStatus = error != nil ? .error : .success

            if searchTerms != nil {
                state.topSearchTerms = searchTerms
            }
        }
    }

    private func receivedVideos(_ videos: StatsTopVideosTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topVideosStatus = error != nil ? .error : .success

            if videos != nil {
                state.topVideos = videos
            }
        }
    }

    private func receivedCountries(_ countries: StatsTopCountryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topCountriesStatus = error != nil ? .error : .success

            if countries != nil {
                state.topCountries = countries
            }
        }
    }

    private func receivedFileDownloads(_ downloads: StatsFileDownloadsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.topFileDownloadsStatus = error != nil ? .error : .success

            if downloads != nil {
                state.topFileDownloads = downloads
            }
        }
    }

    private func receivedPostStats(_ postStats: StatsPostDetails?, _ postId: Int, _ error: Error?) {
        transaction { state in
            state.postStatsFetchingStatuses[postId] = error != nil ? .error : .success
            state.postStats[postId] = postStats
        }
    }

    // MARK: - Helpers

    private func statsRemote() -> StatsServiceRemoteV2? {
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

    private func initializeStatsRemote() {
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

    private func cancelQueries() {
        operationQueue.cancelAllOperations()
        statsServiceRemote?.wordPressComRestApi.cancelTasks()
    }

    private func shouldFetchOverview() -> Bool {
        return [state.timeIntervalsSummaryStatus,
                state.totalsSummaryStatus,
                state.topPostsAndPagesStatus,
                state.topReferrersStatus,
                state.topPublishedStatus,
                state.topClicksStatus,
                state.topAuthorsStatus,
                state.topSearchTermsStatus,
                state.topCountriesStatus,
                state.topVideosStatus,
                state.topFileDownloadsStatus].first { $0 == .loading } == nil
    }

    private func setAllFetchingStatus(_ status: StoreFetchingStatus) {
        transaction { state in
            state.timeIntervalsSummaryStatus = status
            state.totalsSummaryStatus = status
            state.topPostsAndPagesStatus = status
            state.topReferrersStatus = status
            state.topPublishedStatus = status
            state.topClicksStatus = status
            state.topAuthorsStatus = status
            state.topSearchTermsStatus = status
            state.topCountriesStatus = status
            state.topVideosStatus = status
            state.topFileDownloadsStatus = status
        }
    }

    private func shouldFetchPostsAndPages() -> Bool {
        return !isFetchingPostsAndPages
    }

    private func shouldFetchSearchTerms() -> Bool {
        return !isFetchingSearchTerms
    }

    private func shouldFetchVideos() -> Bool {
        return !isFetchingVideos
    }

    private func shouldFetchClicks() -> Bool {
        return !isFetchingClicks
    }

    private func shouldFetchAuthors() -> Bool {
        return !isFetchingAuthors
    }

    private func shouldFetchReferrers() -> Bool {
        return !isFetchingReferrers
    }

    private func shouldFetchCountries() -> Bool {
        return !isFetchingCountries
    }

    private func shouldFetchPublished() -> Bool {
        return !isFetchingPublished
    }

    private func shouldFetchFileDownloads() -> Bool {
        return !isFetchingFileDownloads
    }
    private func shouldFetchPostStats(for postId: Int?) -> Bool {
        return !isFetchingPostStats(for: postId)
    }
}

// MARK: - Public Accessors

extension StatsPeriodStore {

    func getSummary() -> StatsSummaryTimeIntervalData? {
        return state.timeIntervalsSummary
    }

    func getTotalsSummary() -> StatsSummaryTimeIntervalData? {
        return state.totalsSummary
    }

    func getTopPostsAndPages() -> StatsTopPostsTimeIntervalData? {
        return state.topPostsAndPages
    }

    func getTopReferrers() -> StatsTopReferrersTimeIntervalData? {
        return state.topReferrers
    }

    func getTopClicks() -> StatsTopClicksTimeIntervalData? {
        return state.topClicks
    }

    func getTopPublished() -> StatsPublishedPostsTimeIntervalData? {
        return state.topPublished
    }

    func getTopAuthors() -> StatsTopAuthorsTimeIntervalData? {
        return state.topAuthors
    }

    func getTopSearchTerms() -> StatsSearchTermTimeIntervalData? {
        return state.topSearchTerms
    }

    func getTopVideos() -> StatsTopVideosTimeIntervalData? {
        return state.topVideos
    }

    func getTopCountries() -> StatsTopCountryTimeIntervalData? {
        return state.topCountries
    }

    func getTopFileDownloads() -> StatsFileDownloadsTimeIntervalData? {
        return state.topFileDownloads
    }

    func getPostStats(for postId: Int?) -> StatsPostDetails? {
        guard let postId = postId else {
            return nil
        }
        return state.postStats[postId] ?? nil
    }

    func getMostRecentDate(forPost postId: Int?) -> Date? {
        guard let postId = postId,
            let postStats = state.postStats[postId],
            let mostRecentDay = postStats?.recentWeeks.last?.endDay else {
                return nil
        }

        return Calendar.autoupdatingCurrent.date(from: mostRecentDay)
    }

    var timeIntervalsSummaryStatus: StoreFetchingStatus {
        return state.timeIntervalsSummaryStatus
    }

    var totalsSummaryStatus: StoreFetchingStatus {
        return state.totalsSummaryStatus
    }

    var isFetchingSummary: Bool {
        return timeIntervalsSummaryStatus == .loading
    }

    var topPostsAndPagesStatus: StoreFetchingStatus {
        return state.topPostsAndPagesStatus
    }

    var topReferrersStatus: StoreFetchingStatus {
        return state.topReferrersStatus
    }

    var topPublishedStatus: StoreFetchingStatus {
        return state.topPublishedStatus
    }

    var topClicksStatus: StoreFetchingStatus {
        return state.topClicksStatus
    }

    var topAuthorsStatus: StoreFetchingStatus {
        return state.topAuthorsStatus
    }

    var topSearchTermsStatus: StoreFetchingStatus {
        return state.topSearchTermsStatus
    }

    var topCountriesStatus: StoreFetchingStatus {
        return state.topCountriesStatus
    }

    var topVideosStatus: StoreFetchingStatus {
        return state.topVideosStatus
    }

    var topFileDownloadsStatus: StoreFetchingStatus {
        return state.topFileDownloadsStatus
    }

    var isFetchingPostsAndPages: Bool {
        return topPostsAndPagesStatus == .loading
    }

    var isFetchingSearchTerms: Bool {
        return topSearchTermsStatus == .loading
    }

    var isFetchingVideos: Bool {
        return topVideosStatus == .loading
    }

    var isFetchingClicks: Bool {
        return topClicksStatus == .loading
    }

    var isFetchingAuthors: Bool {
        return topAuthorsStatus == .loading
    }

    var isFetchingReferrers: Bool {
        return topReferrersStatus == .loading
    }

    var isFetchingCountries: Bool {
        return topCountriesStatus == .loading
    }

    var isFetchingPublished: Bool {
        return topPublishedStatus == .loading
    }

    var isFetchingFileDownloads: Bool {
        return topFileDownloadsStatus == .loading
    }

    var fetchingOverviewHasFailed: Bool {
        return [state.timeIntervalsSummaryStatus,
                state.totalsSummaryStatus,
                state.topPostsAndPagesStatus,
                state.topReferrersStatus,
                state.topPublishedStatus,
                state.topClicksStatus,
                state.topAuthorsStatus,
                state.topSearchTermsStatus,
                state.topCountriesStatus,
                state.topVideosStatus,
                state.topFileDownloadsStatus].first { $0 != .error } == nil
    }

    func fetchingFailed(for query: PeriodQuery) -> Bool {
        switch query {
        case .allCachedPeriodData:
            return fetchingOverviewHasFailed
        case .allPostsAndPages:
            return topPostsAndPagesStatus == .error
        case .allSearchTerms:
            return topSearchTermsStatus == .error
        case .allVideos:
            return topVideosStatus == .error
        case .allClicks:
            return topClicksStatus == .error
        case .allAuthors:
            return topAuthorsStatus == .error
        case .allReferrers:
            return topReferrersStatus == .error
        case .allCountries:
            return topCountriesStatus == .error
        case .allPublished:
            return topPublishedStatus == .error
        case .allFileDownloads:
            return topFileDownloadsStatus == .error
        case .postStats(let postId):
            return state.postStatsFetchingStatuses[postId] == .error
        case .trafficOverviewData:
            return fetchingOverviewHasFailed
        }
    }

    var containsCachedData: Bool {
        return containsCachedData(for: PeriodType.allCases)
    }

    func isFetchingPostStats(for postId: Int?) -> Bool {
        guard let postId = postId else {
            return false
        }
        return state.postStatsFetchingStatuses[postId] == .loading
    }

    func postStatsFetchingStatuses(for postId: Int?) -> StoreFetchingStatus {
        guard let postId = postId,
            let status = state.postStatsFetchingStatuses[postId] else {
            return .idle
        }
        return status
    }

    private func toggleSpamState(for referrerDomain: String, currentValue: Bool) {
        for (index, referrer) in (state.topReferrers?.referrers ?? []).enumerated() {
            guard (referrer.children.isEmpty && referrer.url?.host == referrerDomain) ||
                    referrer.children.first?.url?.host == referrerDomain else {
                continue
            }

            toggleSpamState(for: referrerDomain,
                            currentValue: currentValue,
                            referrerIndex: index,
                            hasChildren: !referrer.children.isEmpty) { [weak self] in
                switch $0 {
                case .success:
                    self?.delegate?.didChangeSpamState(for: referrerDomain, isSpam: !currentValue)
                case .failure:
                    self?.delegate?.changingSpamStateForReferrerDomainFailed(oldValue: currentValue)
                }
            }
            break
        }
    }
}

// MARK: - Widget Data

private extension PeriodStoreState {

    // Store data for the iOS 14 Today widget. We don't need to check if the site
    // matches here, as `storeHomeWidgetData` does that for us.
    private func storeTodayHomeWidgetData() {
        guard timeIntervalsSummary?.period == .day,
              timeIntervalsSummary?.periodEndDate == StatsDataHelper.currentDateForSite().normalizedDate(),
              let todayData = timeIntervalsSummary?.summaryData.last else {
            return
        }

        let todayWidgetStats = TodayWidgetStats(views: todayData.viewsCount,
                                                visitors: todayData.visitorsCount,
                                                likes: todayData.likesCount,
                                                comments: todayData.commentsCount)
        StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetTodayData.self, stats: todayWidgetStats)
    }
}

// MARK: - Toggle referrer spam state helper

private extension StatsPeriodStore {
    private func toggleSpamState(for referrerDomain: String,
                         currentValue: Bool,
                         referrerIndex: Int,
                         hasChildren: Bool,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        statsServiceRemote?.toggleSpamState(for: referrerDomain, currentValue: currentValue, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.state.topReferrers?.referrers[referrerIndex].isSpam.toggle()
            DDLogInfo("Stats Period: Referrer \(referrerDomain) isSpam set to \(self.state.topReferrers?.referrers[referrerIndex].isSpam ?? false)")

            guard hasChildren else {
                completion(.success(()))
                return
            }
            for (childIndex, _) in (self.state.topReferrers?.referrers[referrerIndex].children ?? []).enumerated() {
                self.state.topReferrers?.referrers[referrerIndex].children[childIndex].isSpam.toggle()
            }

            completion(.success(()))
        }, failure: { error in
            DDLogInfo("Stats Period: Couldn't toggle spam state for referrer \(referrerDomain), reason: \(error.localizedDescription)")
            completion(.failure(error))
        })
    }
}
