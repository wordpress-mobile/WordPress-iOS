import Foundation
import WordPressFlux
import WidgetKit

enum PeriodType: CaseIterable {
    case summary
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

    // Period overview
    case refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool)
    case refreshPeriod(query: PeriodQuery)
    case toggleSpam(referrerDomain: String, currentValue: Bool)
}

enum PeriodQuery {
    case allCachedPeriodData(date: Date, period: StatsPeriodUnit)
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
        case .allCachedPeriodData(let date, _):
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
        default:
            return StatsDataHelper.currentDateForSite().normalizedDate()
        }
    }

    var period: StatsPeriodUnit {
        switch self {
        case .allCachedPeriodData( _, let period):
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
        default:
            return .day
        }
    }
}

struct PeriodStoreState {

    // Period overview

    var summary: StatsSummaryTimeIntervalData? {
        didSet {
            StoreContainer.shared.statsWidgets.updateThisWeekHomeWidget(summary: summary)
            storeTodayHomeWidgetData()
        }
    }

    var summaryStatus: StoreFetchingStatus = .idle

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

class StatsPeriodStore: QueryStore<PeriodStoreState, PeriodQuery> {
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
        state.summary.map { setValue($0, .summary) }
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
        case .allCachedPeriodData:
            loadFromCache(date: query.date, period: query.period)
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
        }
    }

    // Fetch Chart data first using the async operation
    //
    private func fetchChartData(date: Date, period: StatsPeriodUnit) {
        guard let service = statsRemote() else {
            return
        }

        DDLogInfo("Stats Period: Cancel all operations")

        let chartOperation = PeriodOperation(service: service, for: period, date: date, limit: 14) { [weak self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching summary.")

            DispatchQueue.main.async {
                self?.receivedSummary(summary, error)
            }
        }

        operationQueue.addOperation(chartOperation)
    }

    private func fetchAsyncData(date: Date, period: StatsPeriodUnit) {
        let periodQueries: [PeriodQuery] = [
            .allPostsAndPages(date: date, period: period),
            .allSearchTerms(date: date, period: period),
            .allVideos(date: date, period: period),
            .allClicks(date: date, period: period),
            .allAuthors(date: date, period: period),
            .allReferrers(date: date, period: period),
            .allCountries(date: date, period: period),
            .allPublished(date: date, period: period),
            .allFileDownloads(date: date, period: period)
        ]

        periodQueries.forEach {
            DDLogInfo("Stats Period: Start fetching \($0)")
            refreshPeriodData(for: $0)
        }
    }

    private func loadFromCache(date: Date, period: StatsPeriodUnit) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func getValue<T: StatsTimeIntervalData>(_ record: StatsPediodCache.Record) -> T? {
            cache.getValue(record: record, date: date, period: period, siteID: siteID)
        }
        transaction { state in
            state.summary = getValue(.summary)
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

    private func refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool) {
        if forceRefresh {
            cancelQueries()
        }

        loadFromCache(date: date, period: period)

        guard shouldFetchOverview() else {
            DDLogInfo("Stats Period Overview refresh triggered while one was in progress.")
            return
        }

        state.summaryStatus = .loading
        scheduler.debounce { [weak self] in
            self?.fetchChartData(date: date, period: period)
            self?.fetchAsyncData(date: date, period: period)
        }
    }

    private func fetchAllPostsAndPages(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.topPostsAndPagesStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching posts.")

            DispatchQueue.main.async {
                self?.receivedPostsAndPages(posts, error)
            }
            self?.storeDataInCache()
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

        state.topVideosStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (videos: StatsTopVideosTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching videos: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching videos.")

            DispatchQueue.main.async {
                self?.receivedVideos(videos, error)
            }
            self?.storeDataInCache()
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

        state.topAuthorsStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (authors: StatsTopAuthorsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching authors: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching authors.")

            DispatchQueue.main.async {
                self?.receivedAuthors(authors, error)
            }
            self?.storeDataInCache()
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

        state.topReferrersStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching referrers.")

            DispatchQueue.main.async {
                self?.receivedReferrers(referrers, error)
            }
            self?.storeDataInCache()
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

        state.topCountriesStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching countries.")

            DispatchQueue.main.async {
                self?.receivedCountries(countries, error)
            }
            self?.storeDataInCache()
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

        state.topPublishedStatus = .loading

        operationQueue.addOperation(PublishedPostOperation(service: statsRemote, for: period, date: date, limit: 0) { [weak self] (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching published: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching published.")

            DispatchQueue.main.async {
                self?.receivedPublished(published, error)
            }
            self?.storeDataInCache()
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

        state.topFileDownloadsStatus = .loading

        operationQueue.addOperation(PeriodOperation(service: statsRemote, for: period, date: date, limit: 1) { [weak self] (downloads: StatsFileDownloadsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error file downloads: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished file downloads.")

            DispatchQueue.main.async {
                self?.receivedFileDownloads(downloads, error)
            }
            self?.storeDataInCache()
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
        cancelQueries()
        fetchPostStats(postID: postID)
    }

    // MARK: - Receive data methods

    private func receivedSummary(_ summaryData: StatsSummaryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.summaryStatus = error != nil ? .error : .success

            if summaryData != nil {
                state.summary = summaryData
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
        setAllFetchingStatus(.idle)
    }

    private func shouldFetchOverview() -> Bool {
        return [state.summaryStatus,
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
            state.summaryStatus = status
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
        return state.summary
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

    var summaryStatus: StoreFetchingStatus {
        return state.summaryStatus
    }

    var isFetchingSummary: Bool {
        return summaryStatus == .loading
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
        return [state.summaryStatus,
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
        guard summary?.period == .day,
              summary?.periodEndDate == StatsDataHelper.currentDateForSite().normalizedDate(),
              let todayData = summary?.summaryData.last else {
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
