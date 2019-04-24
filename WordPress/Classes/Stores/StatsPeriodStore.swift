import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum PeriodAction: Action {

    // Period overview
    case receivedSummary(_ summary: StatsSummaryTimeIntervalData?)
    case receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?)
    case receivedPublished(_ published: StatsPublishedPostsTimeIntervalData?)
    case receivedReferrers(_ referrers: StatsTopReferrersTimeIntervalData?)
    case receivedClicks(_ clicks: StatsTopClicksTimeIntervalData?)
    case receivedAuthors(_ authors: StatsTopAuthorsTimeIntervalData?)
    case receivedSearchTerms(_ searchTerms: StatsSearchTermTimeIntervalData?)
    case receivedVideos(_ videos: StatsTopVideosTimeIntervalData?)
    case receivedCountries(_ countries: StatsTopCountryTimeIntervalData?)
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

    // Post Stats
    case receivedPostStats(_ postStats: StatsPostDetails?)
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
        default:
            return Date()
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
        default:
            return .day
        }
    }
}

struct PeriodStoreState {

    // Period overview

    var summary: StatsSummaryTimeIntervalData?
    var fetchingSummary = false

    var topPostsAndPages: StatsTopPostsTimeIntervalData?
    var fetchingPostsAndPages = false

    var topReferrers: StatsTopReferrersTimeIntervalData?
    var fetchingReferrers = false

    var topClicks: StatsTopClicksTimeIntervalData?
    var fetchingClicks = false

    var topPublished: StatsPublishedPostsTimeIntervalData?
    var fetchingPublished = false

    var topAuthors: StatsTopAuthorsTimeIntervalData?
    var fetchingAuthors = false

    var topSearchTerms: StatsSearchTermTimeIntervalData?
    var fetchingSearchTerms = false

    var topCountries: StatsTopCountryTimeIntervalData?
    var fetchingCountries = false

    var topVideos: StatsTopVideosTimeIntervalData?
    var fetchingVideos = false

    // Post Stats

    var postStats: StatsPostDetails?
    var fetchingPostStats = false
}

class StatsPeriodStore: QueryStore<PeriodStoreState, PeriodQuery> {

    private var statsServiceRemote: StatsServiceRemoteV2?

    init() {
        super.init(initialState: PeriodStoreState())
    }

    override func onDispatch(_ action: Action) {

        guard let periodAction = action as? PeriodAction else {
            return
        }

        switch periodAction {
        case .receivedSummary(let summary):
            receivedSummary(summary)
        case .receivedPostsAndPages(let postsAndPages):
            receivedPostsAndPages(postsAndPages)
        case .receivedReferrers(let referrers):
            receivedReferrers(referrers)
        case .receivedClicks(let clicks):
            receivedClicks(clicks)
        case .receivedPublished(let published):
            receivedPublished(published)
        case .receivedAuthors(let authors):
            receivedAuthors(authors)
        case .receivedSearchTerms(let searchTerms):
            receivedSearchTerms(searchTerms)
        case .receivedVideos(let videos):
            receivedVideos(videos)
        case .receivedCountries(let countries):
            receivedCountries(countries)
        case .refreshPeriodOverviewData(let date, let period, let forceRefresh):
            refreshPeriodOverviewData(date: date, period: period, forceRefresh: forceRefresh)
        case .refreshPostsAndPages(let date, let period):
            refreshPostsAndPages(date: date, period: period)
        case .refreshSearchTerms(let date, let period):
            refreshSearchTerms(date: date, period: period)
        case .refreshVideos(let date, let period):
            refreshVideos(date: date, period: period)
        case .refreshClicks(let date, let period):
            refreshClicks(date: date, period: period)
        case .refreshAuthors(let date, let period):
            refreshAuthors(date: date, period: period)
        case .refreshReferrers(let date, let period):
            refreshReferrers(date: date, period: period)
        case .refreshCountries(let date, let period):
            refreshCountries(date: date, period: period)
        case .refreshPublished(let date, let period):
            refreshPublished(date: date, period: period)
        case .receivedPostStats(let postStats):
            receivedPostStats(postStats)
        case .refreshPostStats(let postID):
            refreshPostStats(postID: postID)
        }

        if !isFetchingOverview {
            DDLogInfo("Stats: All fetching operations finished.")
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

        try? ContextManager.shared.mainContext.save()
        DDLogInfo("Stats: finished persisting Stats to disk.")
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
            case .postStats:
                if shouldFetchPostStats() {
                    fetchPostStats(postID: query.postID)
                }
            }
        }
    }

    func fetchPeriodOverviewData(date: Date, period: StatsPeriodUnit) {

        loadFromCache(date: date, period: period)

        // This check is done here and not in a layer above because even if we don't want to
        // make a network call for whatever reason, we still want to load the data we have cached.

        guard shouldFetchOverview() else {
            DDLogInfo("Stats Period Overview refresh triggered while one was in progress.")
            return
        }

        guard let statsRemote = statsRemote() else {
            return
        }

        setAllAsFetchingOverview()

        statsRemote.getData(for: period, endingOn: date) { (summary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching summary: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching summary.")

            self.actionDispatcher.dispatch(PeriodAction.receivedSummary(summary))
        }

        statsRemote.getData(for: period, endingOn: date) { (posts: StatsTopPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching posts: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching posts.")

            self.actionDispatcher.dispatch(PeriodAction.receivedPostsAndPages(posts))
        }

        statsRemote.getData(for: period, endingOn: date) { (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching published: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching published.")

            self.actionDispatcher.dispatch(PeriodAction.receivedPublished(published))
        }

        statsRemote.getData(for: period, endingOn: date) { (referrers: StatsTopReferrersTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching referrers.")

            self.actionDispatcher.dispatch(PeriodAction.receivedReferrers(referrers))
        }

        statsRemote.getData(for: period, endingOn: date) { (clicks: StatsTopClicksTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching clicks: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching clicks.")

            self.actionDispatcher.dispatch(PeriodAction.receivedClicks(clicks))
        }

        statsRemote.getData(for: period, endingOn: date) { (authors: StatsTopAuthorsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching authors: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching authors.")

            self.actionDispatcher.dispatch(PeriodAction.receivedAuthors(authors))
        }

        statsRemote.getData(for: period, endingOn: date) { (searchTerms: StatsSearchTermTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching search terms: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching search terms.")

            self.actionDispatcher.dispatch(PeriodAction.receivedSearchTerms(searchTerms))
        }

        statsRemote.getData(for: period, endingOn: date) { (videos: StatsTopVideosTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching videos: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching videos.")

            self.actionDispatcher.dispatch(PeriodAction.receivedVideos(videos))
        }

        statsRemote.getData(for: period, endingOn: date) { (countries: StatsTopCountryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching countries: \(String(describing: error?.localizedDescription))")
            }

            DDLogInfo("Stats: Finished fetching countries.")

            self.actionDispatcher.dispatch(PeriodAction.receivedCountries(countries))
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

        DDLogInfo("Stats: Finished loading data from Core Data.")

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

            DDLogInfo("Stats: Finished setting data to store from Core Data.")
        }
    }

    func refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit, forceRefresh: Bool) {
        // The call to `persistToCoreData()` might seem unintuitive here, at a first glance.
        // It's here because call to this method will usually happen after user selects a different
        // time period they're interested in. If we only relied on calls to `persistToCoreData()`
        // when user has left the screen/app, we would possibly lose on storing A LOT of data.
        persistToCoreData()

        if forceRefresh {
            // Stop existing queries and start fresh.
            statsServiceRemote?.wordPressComRestApi.invalidateAndCancelTasks()
            setAllAsFetchingOverview(fetching: false)
            // invalidateAndCancelTasks invalidates the SessionManager, 
            // so we need to recreate it to run queries.
            initializeStatsRemote()
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

            self.actionDispatcher.dispatch(PeriodAction.receivedPostsAndPages(posts))
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

            self.actionDispatcher.dispatch(PeriodAction.receivedSearchTerms(searchTerms))
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

            self.actionDispatcher.dispatch(PeriodAction.receivedVideos(videos))
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

            self.actionDispatcher.dispatch(PeriodAction.receivedClicks(clicks))
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

            self.actionDispatcher.dispatch(PeriodAction.receivedAuthors(authors))
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

            self.actionDispatcher.dispatch(PeriodAction.receivedReferrers(referrers))
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

            self.actionDispatcher.dispatch(PeriodAction.receivedCountries(countries))
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
            self.actionDispatcher.dispatch(PeriodAction.receivedPublished(published))
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

    func fetchPostStats(postID: Int?) {
        guard
            let postID = postID,
            let statsRemote = statsRemote() else {
                return
        }

        state.fetchingPostStats = true

        statsRemote.getDetails(forPostID: postID) { (postStats: StatsPostDetails?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching Post Stats: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching post stats.")
            self.actionDispatcher.dispatch(PeriodAction.receivedPostStats(postStats))
        }
    }

    func refreshPostStats(postID: Int) {
        guard shouldFetchPostStats() else {
            DDLogInfo("Stats Post Stats refresh triggered while one was in progress.")
            return
        }

        fetchPostStats(postID: postID)
    }

    // MARK: - Receive data methods

    func receivedSummary(_ summaryData: StatsSummaryTimeIntervalData?) {
        transaction { state in
            state.fetchingSummary = false

            if summaryData != nil {
                state.summary = summaryData
            }
        }
    }

    func receivedPostsAndPages(_ postsAndPages: StatsTopPostsTimeIntervalData?) {
        transaction { state in
            state.fetchingPostsAndPages = false

            if postsAndPages != nil {
                state.topPostsAndPages = postsAndPages
            }
        }
    }

    func receivedReferrers(_ referrers: StatsTopReferrersTimeIntervalData?) {
        transaction { state in
            state.fetchingReferrers = false

            if referrers != nil {
                state.topReferrers = referrers
            }
        }
    }

    func receivedClicks(_ clicks: StatsTopClicksTimeIntervalData?) {
        transaction { state in
            state.fetchingClicks = false

            if clicks != nil {
                state.topClicks = clicks
            }
        }
    }

    func receivedAuthors(_ authors: StatsTopAuthorsTimeIntervalData?) {
        transaction { state in
            state.fetchingAuthors = false

            if authors != nil {
                state.topAuthors = authors
            }
        }
    }

    func receivedPublished(_ published: StatsPublishedPostsTimeIntervalData?) {
        transaction { state in
            state.fetchingPublished = false

            if published != nil {
                state.topPublished = published
            }
        }
    }

    func receivedSearchTerms(_ searchTerms: StatsSearchTermTimeIntervalData?) {
        transaction { state in
            state.fetchingSearchTerms = false

            if searchTerms != nil {
                state.topSearchTerms = searchTerms
            }
        }
    }

    func receivedVideos(_ videos: StatsTopVideosTimeIntervalData?) {
        transaction { state in
            state.fetchingVideos = false

            if videos != nil {
                state.topVideos = videos
            }
        }
    }

    func receivedCountries(_ countries: StatsTopCountryTimeIntervalData?) {
        transaction { state in
            state.fetchingCountries = false

            if countries != nil {
                state.topCountries = countries
            }
        }
    }

    func receivedPostStats(_ postStats: StatsPostDetails?) {
        transaction { state in
            state.fetchingPostStats = false

            if postStats != nil {
                state.postStats = postStats
            }
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

        let wpApi = WordPressComRestApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        statsServiceRemote = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: timeZone)
    }

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    func setAllAsFetchingOverview(fetching: Bool = true) {
        state.fetchingPostsAndPages = fetching
        state.fetchingReferrers = fetching
        state.fetchingClicks = fetching
        state.fetchingPublished = fetching
        state.fetchingAuthors = fetching
        state.fetchingSearchTerms = fetching
        state.fetchingVideos = fetching
        state.fetchingCountries = fetching
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

    func shouldFetchPostStats() -> Bool {
        return !isFetchingPostStats
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

    func getPostStats() -> StatsPostDetails? {
        return state.postStats
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
            state.fetchingCountries
    }

    var isFetchingPostsAndPages: Bool {
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

    var isFetchingPostStats: Bool {
        return state.fetchingPostStats
    }

}
