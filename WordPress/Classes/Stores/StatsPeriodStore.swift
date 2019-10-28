import Foundation
import WordPressFlux

enum PeriodType {
    case summary
    case topPostsAndPages
}

enum PeriodAction: Action {

    // Period overview
    case receivedSummary(_ summary: StatsSummaryTimeIntervalData?, _ error: Error?)
    case receivedLikesSummary(_ likes: StatsLikesSummaryTimeIntervalData?, _ error: Error?)
    case receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?, _ error: Error?)
    case receivedPublished(_ published: StatsPublishedPostsTimeIntervalData?, _ error: Error?)
    case receivedReferrers(_ referrers: StatsTopReferrersTimeIntervalData?, _ error: Error?)
    case receivedClicks(_ clicks: StatsTopClicksTimeIntervalData?, _ error: Error?)
    case receivedAuthors(_ authors: StatsTopAuthorsTimeIntervalData?, _ error: Error?)
    case receivedSearchTerms(_ searchTerms: StatsSearchTermTimeIntervalData?, _ error: Error?)
    case receivedVideos(_ videos: StatsTopVideosTimeIntervalData?, _ error: Error?)
    case receivedCountries(_ countries: StatsTopCountryTimeIntervalData?, _ error: Error?)
    case receivedFileDownloads(_ downloads: StatsFileDownloadsTimeIntervalData?, _ error: Error?)
    case refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool)

    // Period details
    case refreshPostsAndPages(date: Date, period: StatsPeriodUnit)
    case refreshPublished(date: Date, period: StatsPeriodUnit)
    case refreshReferrers(date: Date, period: StatsPeriodUnit)
    case refreshClicks(date: Date, period: StatsPeriodUnit)
    case refreshAuthors(date: Date, period: StatsPeriodUnit)
    case refreshSearchTerms(date: Date, period: StatsPeriodUnit)
    case refreshVideos(date: Date, period: StatsPeriodUnit)
    case refreshCountries(date: Date, period: StatsPeriodUnit)
    case refreshFileDownloads(date: Date, period: StatsPeriodUnit)

    // Post Stats
    case receivedPostStats(_ postStats: StatsPostDetails?, _ postId: Int, _ error: Error?)
    case refreshPostStats(postID: Int)
}

enum PeriodQuery {
    case periods(date: Date, period: StatsPeriodUnit)
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
        case .periods(let date, _):
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
        case .periods( _, let period):
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

    var summary: StatsSummaryTimeIntervalData?
    var summaryStatus: StoreFetchingStatus = .idle
    var fetchingSummary = false
    var fetchingSummaryHasFailed = false
    var fetchingSummaryLikes = false

    var topPostsAndPages: StatsTopPostsTimeIntervalData?
    var topPostsAndPagesStatus: StoreFetchingStatus = .idle
    var fetchingPostsAndPages = false
    var fetchingPostsAndPagesHasFailed = false

    var topReferrers: StatsTopReferrersTimeIntervalData?
    var fetchingReferrers = false
    var fetchingReferrersHasFailed = false

    var topClicks: StatsTopClicksTimeIntervalData?
    var fetchingClicks = false
    var fetchingClicksHasFailed = false

    var topPublished: StatsPublishedPostsTimeIntervalData?
    var fetchingPublished = false
    var fetchingPublishedHasFailed = false

    var topAuthors: StatsTopAuthorsTimeIntervalData?
    var fetchingAuthors = false
    var fetchingAuthorsHasFailed = false

    var topSearchTerms: StatsSearchTermTimeIntervalData?
    var fetchingSearchTerms = false
    var fetchingSearchTermsHasFailed = false

    var topCountries: StatsTopCountryTimeIntervalData?
    var fetchingCountries = false
    var fetchingCountriesHasFailed = false

    var topVideos: StatsTopVideosTimeIntervalData?
    var fetchingVideos = false
    var fetchingVideosHasFailed = false

    var topFileDownloads: StatsFileDownloadsTimeIntervalData?
    var fetchingFileDownloads = false
    var fetchingFileDownloadsHasFailed = false

    // Post Stats

    var postStats = [Int: StatsPostDetails?]()
    var fetchingPostStats = [Int: Bool]()
    var fetchingPostStatsHasFailed = [Int: Bool]()
}

class StatsPeriodStore: QueryStore<PeriodStoreState, PeriodQuery> {
    private typealias PeriodOperation = StatsPeriodAsyncOperation

    var fetchingOverviewListener: ((_ fetching: Bool, _ success: Bool) -> Void)?
    var cachedDataListener: ((_ hasCachedData: Bool) -> Void)?

    private var statsServiceRemote: StatsServiceRemoteV2?
    private var operationQueue = OperationQueue()
    private let scheduler = Scheduler(seconds: 0.3)

    init() {
        super.init(initialState: PeriodStoreState())
    }

    override func onDispatch(_ action: Action) {

        guard let periodAction = action as? PeriodAction else {
            return
        }

        switch periodAction {
        case .receivedSummary(let summary, let error):
            receivedSummary(summary, error)
        case .receivedLikesSummary(let likes, let error):
            receivedLikesSummary(likes, error)
        case .receivedPostsAndPages(let postsAndPages, let error):
            receivedPostsAndPages(postsAndPages, error)
        case .refreshPostsAndPages(let date, let period):
            refreshPostsAndPages(date: date, period: period)
        case .receivedReferrers(let referrers, let error):
            receivedReferrers(referrers, error)
        case .refreshReferrers(let date, let period):
            refreshReferrers(date: date, period: period)
        case .receivedClicks(let clicks, let error):
            receivedClicks(clicks, error)
        case .refreshClicks(let date, let period):
            refreshClicks(date: date, period: period)
        case .receivedPublished(let published, let error):
            receivedPublished(published, error)
        case .refreshPublished(let date, let period):
            refreshPublished(date: date, period: period)
        case .receivedAuthors(let authors, let error):
            receivedAuthors(authors, error)
        case .refreshAuthors(let date, let period):
            refreshAuthors(date: date, period: period)
        case .receivedSearchTerms(let searchTerms, let error):
            receivedSearchTerms(searchTerms, error)
        case .refreshSearchTerms(let date, let period):
            refreshSearchTerms(date: date, period: period)
        case .receivedVideos(let videos, let error):
            receivedVideos(videos, error)
        case .refreshVideos(let date, let period):
            refreshVideos(date: date, period: period)
        case .receivedCountries(let countries, let error):
            receivedCountries(countries, error)
        case .refreshCountries(let date, let period):
            refreshCountries(date: date, period: period)
        case .receivedFileDownloads(let downloads, let error):
            receivedFileDownloads(downloads, error)
        case .refreshFileDownloads(let date, let period):
            refreshFileDownloads(date: date, period: period)
        case .receivedPostStats(let postStats, let postId, let error):
            receivedPostStats(postStats, postId, error)
        case .refreshPostStats(let postID):
            refreshPostStats(postID: postID)
        case .refreshPeriodOverviewData(let date, let period, let forceRefresh):
            refreshPeriodOverviewData(date: date, period: period, forceRefresh: forceRefresh)
        }

        if !isFetchingOverview {
            DDLogInfo("Stats: Period Overview fetching operations finished.")
            fetchingOverviewListener?(false, fetchingOverviewHasFailed)
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    func persistToCoreData() {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = BlogService.withMainContext().blog(byBlogId: siteID) else {
                return
        }

        _ = state.summary.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topPostsAndPages.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topReferrers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topClicks.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topPublished.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topAuthors.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topSearchTerms.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topCountries.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topVideos.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topFileDownloads.flatMap { StatsRecord.record(from: $0, for: blog) }

        try? ContextManager.shared.mainContext.save()
        DDLogInfo("Stats: finished persisting Period Stats to disk.")
    }
}

// MARK: - Private Methods

private extension StatsPeriodStore {

    // MARK: - Get Data

    func processQueries() {

        guard !activeQueries.isEmpty else {
            return
        }

        activeQueries.forEach { query in
            switch query {
            case .periods:
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
    }

    func fetchPeriodOverviewData(date: Date, period: StatsPeriodUnit) {
        loadFromCache(date: date, period: period)

        guard shouldFetchOverview() else {
            if !Feature.enabled(.statsAsyncLoadingDWMY) {
                fetchingOverviewListener?(true, false)
            }
            DDLogInfo("Stats Period Overview refresh triggered while one was in progress.")
            return
        }

        if Feature.enabled(.statsAsyncLoadingDWMY) {
            setAllFetchingStatus(.loading)
            scheduler.debounce { [weak self] in
                self?.fetchChartData(date: date, period: period)
            }
            return
        }

        // Legacy overview fetching method
        //
        fetchSyncData(date: date, period: period)
    }

    // Fetch Chart data first using the async operation
    //
    func fetchChartData(date: Date, period: StatsPeriodUnit) {
        guard let service = statsRemote() else {
            return
        }

        DDLogInfo("Stats Period: Cancel all operations")

        operationQueue.cancelAllOperations()

        let chartOperation = PeriodOperation(service: service, for: period, date: date, limit: 14) { [weak self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching summary.")

            DispatchQueue.main.async {
                self?.receivedSummary(summary, error)
                self?.fetchAsyncData(date: date, period: period)
            }
        }

        operationQueue.addOperation(chartOperation)
    }

    // Fetch the rest of the overview data using the async operations
    //
    func fetchAsyncData(date: Date, period: StatsPeriodUnit) {
        guard let service = statsRemote() else {
            return
        }

        let likesOperation = PeriodOperation(service: service, for: period, date: date, limit: 14) { [weak self] (likes: StatsLikesSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching likes summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period:  Finished fetching likes summary.")
            DispatchQueue.main.async {
                self?.receivedLikesSummary(likes, error)
            }
        }

        let topPostsOperation = PeriodOperation(service: service, for: period, date: date) { [weak self] (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("Stats Period: Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats Period: Finished fetching posts.")

            DispatchQueue.main.async {
                self?.receivedPostsAndPages(posts, error)
            }
        }

        operationQueue.addOperations([likesOperation,
                                      topPostsOperation],
                                     waitUntilFinished: false)
    }

    func fetchSyncData(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        setAllAsFetchingOverview()

        fetchingOverviewListener?(true, false)

        statsRemote.getData(for: period, endingOn: date, limit: 14) { (summary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching summary.")

            self.actionDispatcher.dispatch(PeriodAction.receivedSummary(summary, error))
            self.fetchSummaryLikesData(date: date, period: period)
        }

        statsRemote.getData(for: period, endingOn: date) { (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching posts.")

            self.actionDispatcher.dispatch(PeriodAction.receivedPostsAndPages(posts, error))
        }

        statsRemote.getData(for: period, endingOn: date) { (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching published: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching published.")

            self.actionDispatcher.dispatch(PeriodAction.receivedPublished(published, error))
        }

        statsRemote.getData(for: period, endingOn: date) { (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching referrers.")

            self.actionDispatcher.dispatch(PeriodAction.receivedReferrers(referrers, error))
        }

        statsRemote.getData(for: period, endingOn: date) { (clicks: StatsTopClicksTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching clicks: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching clicks.")

            self.actionDispatcher.dispatch(PeriodAction.receivedClicks(clicks, error))
        }

        statsRemote.getData(for: period, endingOn: date) { (authors: StatsTopAuthorsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching authors: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching authors.")

            self.actionDispatcher.dispatch(PeriodAction.receivedAuthors(authors, error))
        }

        statsRemote.getData(for: period, endingOn: date) { (searchTerms: StatsSearchTermTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching search terms: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching search terms.")

            self.actionDispatcher.dispatch(PeriodAction.receivedSearchTerms(searchTerms, error))
        }

        statsRemote.getData(for: period, endingOn: date) { (videos: StatsTopVideosTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching videos: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching videos.")

            self.actionDispatcher.dispatch(PeriodAction.receivedVideos(videos, error))
        }

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching countries.")

            self.actionDispatcher.dispatch(PeriodAction.receivedCountries(countries, error))
        }

        // 'limit' in this context is used for the 'num' parameter for the 'file-downloads' endpoint.
        // 'num' relates to the "number of periods to include in the query".
        statsRemote.getData(for: period, endingOn: date, limit: 1) { (downloads: StatsFileDownloadsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching file downloads: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching file downloads.")

            self.actionDispatcher.dispatch(PeriodAction.receivedFileDownloads(downloads, error))
        }
    }

    func fetchSummaryLikesData(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        statsRemote.getData(for: period, endingOn: date, limit: 14) { (likes: StatsLikesSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching likes summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching likes summary.")
            DispatchQueue.main.async {
                self.actionDispatcher.dispatch(PeriodAction.receivedLikesSummary(likes, error))
            }
        }
    }

    func loadFromCache(date: Date, period: StatsPeriodUnit) {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = BlogService.withMainContext().blog(byBlogId: siteID) else {
                return
        }

        let summary = StatsRecord.timeIntervalData(for: blog, type: .blogVisitsSummary, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let posts = StatsRecord.timeIntervalData(for: blog, type: .topViewedPost, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let referrers = StatsRecord.timeIntervalData(for: blog, type: .referrers, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let clicks = StatsRecord.timeIntervalData(for: blog, type: .clicks, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let published = StatsRecord.timeIntervalData(for: blog, type: .publishedPosts, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let authors = StatsRecord.timeIntervalData(for: blog, type: .topViewedAuthor, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let searchTerms = StatsRecord.timeIntervalData(for: blog, type: .searchTerms, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let countries = StatsRecord.timeIntervalData(for: blog, type: .countryViews, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let videos = StatsRecord.timeIntervalData(for: blog, type: .videos, period: StatsRecordPeriodType(remoteStatus: period), date: date)
        let fileDownloads = StatsRecord.timeIntervalData(for: blog, type: .fileDownloads, period: StatsRecordPeriodType(remoteStatus: period), date: date)

        DDLogInfo("Stats: Finished loading Period data from Core Data.")

        transaction { state in
            state.summary = summary.flatMap { StatsSummaryTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topPostsAndPages = posts.flatMap { StatsTopPostsTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topReferrers = referrers.flatMap { StatsTopReferrersTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topClicks = clicks.flatMap { StatsTopClicksTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topPublished = published.flatMap { StatsPublishedPostsTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topAuthors = authors.flatMap { StatsTopAuthorsTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topSearchTerms = searchTerms.flatMap { StatsSearchTermTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topCountries = countries.flatMap { StatsTopCountryTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topVideos = videos.flatMap { StatsTopVideosTimeIntervalData(statsRecordValues: $0.recordValues) }
            state.topFileDownloads = fileDownloads.flatMap { StatsFileDownloadsTimeIntervalData(statsRecordValues: $0.recordValues) }

            DDLogInfo("Stats: Finished setting data to Period store from Core Data.")
        }

        cachedDataListener?(containsCachedData)
    }

    func refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool) {
        // The call to `persistToCoreData()` might seem unintuitive here, at a first glance.
        // It's here because call to this method will usually happen after user selects a different
        // time period they're interested in. If we only relied on calls to `persistToCoreData()`
        // when user has left the screen/app, we would possibly lose on storing A LOT of data.
        persistToCoreData()

        if forceRefresh && !Feature.enabled(.statsAsyncLoadingDWMY) {
            setAllAsFetchingOverview(fetching: false)
            cancelQueries()
        }

        fetchPeriodOverviewData(date: date, period: period)
    }

    func fetchAllPostsAndPages(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingPostsAndPages = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all posts.")

            self.actionDispatcher.dispatch(PeriodAction.receivedPostsAndPages(posts, error))
            self.persistToCoreData()
        }
    }

    func refreshPostsAndPages(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPostsAndPages() else {
            DDLogInfo("Stats Period Posts And Pages refresh triggered while one was in progress.")
            return
        }

        fetchAllPostsAndPages(date: date, period: period)
    }

    func fetchAllSearchTerms(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingSearchTerms = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (searchTerms: StatsSearchTermTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all search terms: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all search terms.")

            self.actionDispatcher.dispatch(PeriodAction.receivedSearchTerms(searchTerms, error))
            self.persistToCoreData()
        }
    }

    func refreshSearchTerms(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchSearchTerms() else {
            DDLogInfo("Stats Period Search Terms refresh triggered while one was in progress.")
            return
        }

        fetchAllSearchTerms(date: date, period: period)
    }

    func fetchAllVideos(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingVideos = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (videos: StatsTopVideosTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching videos: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching videos.")

            self.actionDispatcher.dispatch(PeriodAction.receivedVideos(videos, error))
            self.persistToCoreData()
        }
    }

    func refreshVideos(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchVideos() else {
            DDLogInfo("Stats Period Videos refresh triggered while one was in progress.")
            return
        }

        fetchAllVideos(date: date, period: period)
    }

    func fetchAllClicks(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingClicks = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (clicks: StatsTopClicksTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all clicks: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all clicks.")

            self.actionDispatcher.dispatch(PeriodAction.receivedClicks(clicks, error))
            self.persistToCoreData()
        }
    }

    func refreshClicks(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchClicks() else {
            DDLogInfo("Stats Period Clicks refresh triggered while one was in progress.")
            return
        }

        fetchAllClicks(date: date, period: period)
    }

    func fetchAllAuthors(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingAuthors = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (authors: StatsTopAuthorsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all authors: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all authors.")

            self.actionDispatcher.dispatch(PeriodAction.receivedAuthors(authors, error))
            self.persistToCoreData()
        }
    }

    func refreshAuthors(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchAuthors() else {
            DDLogInfo("Stats Period Authors refresh triggered while one was in progress.")
            return
        }

        fetchAllAuthors(date: date, period: period)
    }

    func fetchAllReferrers(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingReferrers = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all referrers.")

            self.actionDispatcher.dispatch(PeriodAction.receivedReferrers(referrers, error))
            self.persistToCoreData()
        }
    }

    func refreshReferrers(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchReferrers() else {
            DDLogInfo("Stats Period Referrers refresh triggered while one was in progress.")
            return
        }

        fetchAllReferrers(date: date, period: period)
    }

    func fetchAllCountries(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingCountries = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all countries.")

            self.actionDispatcher.dispatch(PeriodAction.receivedCountries(countries, error))
            self.persistToCoreData()
        }
    }

    func refreshCountries(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchCountries() else {
            DDLogInfo("Stats Period Countries refresh triggered while one was in progress.")
            return
        }

        fetchAllCountries(date: date, period: period)
    }

    func fetchAllPublished(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingPublished = true

        statsRemote.getData(for: period, endingOn: date, limit: 0) { (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all Published: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all published.")
            self.actionDispatcher.dispatch(PeriodAction.receivedPublished(published, error))
            self.persistToCoreData()
        }
    }

    func refreshPublished(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPublished() else {
            DDLogInfo("Stats Period Published refresh triggered while one was in progress.")
            return
        }

        fetchAllPublished(date: date, period: period)
    }

    func fetchAllFileDownloads(date: Date, period: StatsPeriodUnit) {
        guard let statsRemote = statsRemote() else {
            return
        }

        state.fetchingFileDownloads = true

        // 'limit' in this context is used for the 'num' parameter for the 'file-downloads' endpoint.
        // 'num' relates to the "number of periods to include in the query".
        statsRemote.getData(for: period, endingOn: date, limit: 1) { (downloads: StatsFileDownloadsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all file downloads: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching all file downloads.")

            self.actionDispatcher.dispatch(PeriodAction.receivedFileDownloads(downloads, error))
            self.persistToCoreData()
        }
    }

    func refreshFileDownloads(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchFileDownloads() else {
            DDLogInfo("Stats Period File Downloads refresh triggered while one was in progress.")
            return
        }

        fetchAllFileDownloads(date: date, period: period)
    }

    func fetchPostStats(postID: Int?) {
        guard
            let postID = postID,
            let statsRemote = statsRemote() else {
                return
        }

        state.fetchingPostStats[postID] = true

        statsRemote.getDetails(forPostID: postID) { (postStats: StatsPostDetails?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching Post Stats: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching post stats.")
            self.actionDispatcher.dispatch(PeriodAction.receivedPostStats(postStats, postID, error))
        }
    }

    func refreshPostStats(postID: Int) {
        state.fetchingPostStats[postID] = false
        cancelQueries()
        fetchPostStats(postID: postID)
    }

    // MARK: - Receive data methods

    func receivedSummary(_ summaryData: StatsSummaryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingSummary = false
            state.fetchingSummaryHasFailed = error != nil
            state.summaryStatus = error != nil ? .error : .success

            if summaryData != nil {
                state.summary = summaryData
            }
        }
    }

    func receivedLikesSummary(_ likesSummary: StatsLikesSummaryTimeIntervalData?, _ error: Error?) {
        // This is a workaround for how our API works — the requests for summary for long periods of times
        // can take extreme amounts of time to finish (and semi-frequenty fail). In order to not block the UI
        // here, we split out the views/visitors/comments and likes requests.
        // This method splices the results of the two back together so we can persist it to Core Data.
        guard
            let summary = likesSummary,
            let currentSummary = state.summary,
            summary.summaryData.count == currentSummary.summaryData.count
            else {
                return
        }

        let newSummaryData = currentSummary.summaryData.enumerated().map { index, obj in
            return StatsSummaryData(period: obj.period,
                                    periodStartDate: obj.periodStartDate,
                                    viewsCount: obj.viewsCount,
                                    visitorsCount: obj.visitorsCount,
                                    likesCount: summary.summaryData[index].likesCount,
                                    commentsCount: obj.commentsCount)
        }

        let newSummary = StatsSummaryTimeIntervalData(period: currentSummary.period,
                                                      periodEndDate: currentSummary.periodEndDate,
                                                      summaryData: newSummaryData)

        transaction { state in
            state.fetchingSummaryLikes = false
            state.summary = newSummary
        }

    }

    func receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingPostsAndPages = false
            state.fetchingPostsAndPagesHasFailed = error != nil
            state.topPostsAndPagesStatus = error != nil ? .error : .success

            if postsAndPages != nil {
                state.topPostsAndPages = postsAndPages
            }
        }
    }

    func receivedReferrers(_ referrers: StatsTopReferrersTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingReferrers = false
            state.fetchingReferrersHasFailed = error != nil

            if referrers != nil {
                state.topReferrers = referrers
            }
        }
    }

    func receivedClicks(_ clicks: StatsTopClicksTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingClicks = false
            state.fetchingClicksHasFailed = error != nil

            if clicks != nil {
                state.topClicks = clicks
            }
        }
    }

    func receivedAuthors(_ authors: StatsTopAuthorsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingAuthors = false
            state.fetchingAuthorsHasFailed = error != nil

            if authors != nil {
                state.topAuthors = authors
            }
        }
    }

    func receivedPublished(_ published: StatsPublishedPostsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingPublished = false
            state.fetchingPublishedHasFailed = error != nil

            if published != nil {
                state.topPublished = published
            }
        }
    }

    func receivedSearchTerms(_ searchTerms: StatsSearchTermTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingSearchTerms = false
            state.fetchingSearchTermsHasFailed = error != nil

            if searchTerms != nil {
                state.topSearchTerms = searchTerms
            }
        }
    }

    func receivedVideos(_ videos: StatsTopVideosTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingVideos = false
            state.fetchingVideosHasFailed = error != nil

            if videos != nil {
                state.topVideos = videos
            }
        }
    }

    func receivedCountries(_ countries: StatsTopCountryTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingCountries = false
            state.fetchingCountriesHasFailed = error != nil

            if countries != nil {
                state.topCountries = countries
            }
        }
    }

    func receivedFileDownloads(_ downloads: StatsFileDownloadsTimeIntervalData?, _ error: Error?) {
        transaction { state in
            state.fetchingFileDownloads = false
            state.fetchingFileDownloadsHasFailed = error != nil

            if downloads != nil {
                state.topFileDownloads = downloads
            }
        }
    }

    func receivedPostStats(_ postStats: StatsPostDetails?, _ postId: Int, _ error: Error?) {
        transaction { state in
            state.fetchingPostStats[postId] = false
            state.fetchingPostStatsHasFailed[postId] = error != nil
            state.postStats[postId] = postStats
        }
    }

    // MARK: - Helpers

    func statsRemote() -> StatsServiceRemoteV2? {

        if statsServiceRemote == nil {
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

    func cancelQueries() {
        statsServiceRemote?.wordPressComRestApi.invalidateAndCancelTasks()
        // `invalidateAndCancelTasks` invalidates the SessionManager,
        // so we need to recreate it to run queries.
        initializeStatsRemote()
    }

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    func setAllAsFetchingOverview(fetching: Bool = true) {
        state.fetchingSummary = fetching
        state.fetchingSummaryLikes = fetching
        state.fetchingPostsAndPages = fetching
        state.fetchingReferrers = fetching
        state.fetchingClicks = fetching
        state.fetchingPublished = fetching
        state.fetchingAuthors = fetching
        state.fetchingSearchTerms = fetching
        state.fetchingVideos = fetching
        state.fetchingCountries = fetching
    }

    func setAllFetchingStatus(_ status: StoreFetchingStatus) {
        state.summaryStatus = status
        state.topPostsAndPagesStatus = status
    }

    func shouldFetchPostsAndPages() -> Bool {
        return !isFetchingPostsAndPages
    }

    func shouldFetchSearchTerms() -> Bool {
        return !isFetchingSearchTerms
    }

    func shouldFetchVideos() -> Bool {
        return !isFetchingVideos
    }

    func shouldFetchClicks() -> Bool {
        return !isFetchingClicks
    }

    func shouldFetchAuthors() -> Bool {
        return !isFetchingAuthors
    }

    func shouldFetchReferrers() -> Bool {
        return !isFetchingReferrers
    }

    func shouldFetchCountries() -> Bool {
        return !isFetchingCountries
    }

    func shouldFetchPublished() -> Bool {
        return !isFetchingPublished
    }

    func shouldFetchFileDownloads() -> Bool {
        return !isFetchingFileDownloads
    }
    func shouldFetchPostStats(for postId: Int?) -> Bool {
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

    var isFetchingOverview: Bool {
        return
            state.fetchingSummary ||
            state.fetchingPostsAndPages ||
            state.fetchingReferrers ||
            state.fetchingClicks ||
            state.fetchingPublished ||
            state.fetchingAuthors ||
            state.fetchingSearchTerms ||
            state.fetchingVideos ||
            state.fetchingCountries ||
            state.fetchingFileDownloads
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

    var isFetchingSummaryLikes: Bool {
        return state.fetchingSummaryLikes
    }

    var isFetchingPostsAndPages: Bool {
        if Feature.enabled(.statsAsyncLoadingDWMY) {
            return topPostsAndPagesStatus == .loading
        }
        return state.fetchingPostsAndPages
    }

    var isFetchingSearchTerms: Bool {
        return state.fetchingSearchTerms
    }

    var isFetchingVideos: Bool {
        return state.fetchingVideos
    }

    var isFetchingClicks: Bool {
        return state.fetchingClicks
    }

    var isFetchingAuthors: Bool {
        return state.fetchingAuthors
    }

    var isFetchingReferrers: Bool {
        return state.fetchingReferrers
    }

    var isFetchingCountries: Bool {
        return state.fetchingCountries
    }

    var isFetchingPublished: Bool {
        return state.fetchingPublished
    }

    var isFetchingFileDownloads: Bool {
        return state.fetchingFileDownloads
    }

    var fetchingOverviewHasFailed: Bool {
        if Feature.enabled(.statsAsyncLoadingDWMY) {
            return state.summaryStatus == .error &&
                state.topPostsAndPagesStatus == .error
        }

        return state.fetchingSummaryHasFailed &&
            state.fetchingPostsAndPagesHasFailed &&
            state.fetchingReferrersHasFailed &&
            state.fetchingClicksHasFailed &&
            state.fetchingPublishedHasFailed &&
            state.fetchingAuthorsHasFailed &&
            state.fetchingSearchTermsHasFailed &&
            state.fetchingVideosHasFailed &&
            state.fetchingCountriesHasFailed &&
            state.fetchingFileDownloadsHasFailed
    }

    func fetchingFailed(for query: PeriodQuery) -> Bool {
        switch query {
        case .periods:
            return fetchingOverviewHasFailed
        case .allPostsAndPages:
            return state.fetchingPostsAndPagesHasFailed
        case .allSearchTerms:
            return state.fetchingSearchTermsHasFailed
        case .allVideos:
            return state.fetchingVideosHasFailed
        case .allClicks:
            return state.fetchingClicksHasFailed
        case .allAuthors:
            return state.fetchingAuthorsHasFailed
        case .allReferrers:
            return state.fetchingReferrersHasFailed
        case .allCountries:
            return state.fetchingCountriesHasFailed
        case .allPublished:
            return state.fetchingPublishedHasFailed
        case .allFileDownloads:
            return state.fetchingFileDownloadsHasFailed
        case .postStats(let postId):
            return state.fetchingPostStatsHasFailed[postId] ?? true
        }
    }

    var containsCachedData: Bool {
        if Feature.enabled(.statsAsyncLoadingDWMY) {
            return containsCachedData(for: [.summary,
                                            .topPostsAndPages])
        }

        if state.summary != nil ||
            state.topPostsAndPages != nil ||
            state.topReferrers != nil ||
            state.topClicks != nil ||
            state.topPublished != nil ||
            state.topAuthors != nil ||
            state.topSearchTerms != nil ||
            state.topCountries != nil ||
            state.topVideos != nil ||
            state.topFileDownloads != nil {
            return true
        }

        return false
    }

    func isFetchingPostStats(for postId: Int?) -> Bool {
        guard let postId = postId else {
            return false
        }
        return state.fetchingPostStats[postId] ?? false
    }
}
