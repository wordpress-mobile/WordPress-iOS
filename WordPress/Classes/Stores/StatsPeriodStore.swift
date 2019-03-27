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
    case refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit)

    // Period details

    case receivedAllPostsAndPages(_ postsAndPages: StatsGroup?)
    case refreshPostsAndPages(date: Date, period: StatsPeriodUnit)

    case receivedAllSearchTerms(_ searchTerms: StatsGroup?)
    case refreshSearchTerms(date: Date, period: StatsPeriodUnit)

    case receivedAllVideos(_ videos: StatsGroup?)
    case refreshVideos(date: Date, period: StatsPeriodUnit)

    case receivedAllClicks(_ clicks: StatsGroup?)
    case refreshClicks(date: Date, period: StatsPeriodUnit)

    case receivedAllAuthors(_ authors: StatsGroup?)
    case refreshAuthors(date: Date, period: StatsPeriodUnit)

    case receivedAllReferrers(_ referrers: StatsGroup?)
    case refreshReferrers(date: Date, period: StatsPeriodUnit)

    case receivedAllCountries(_ countries: StatsGroup?)
    case refreshCountries(date: Date, period: StatsPeriodUnit)

    case receivedAllPublished(_ published: StatsPublishedPostsTimeIntervalData?)
    case refreshPublished(date: Date, period: StatsPeriodUnit)
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

    // Period details

    var allPostsAndPages: [StatsItem]?
    var fetchingAllPostsAndPages = false

    var allSearchTerms: [StatsItem]?
    var fetchingAllSearchTerms = false

    var allVideos: [StatsItem]?
    var fetchingAllVideos = false

    var allClicks: [StatsItem]?
    var fetchingAllClicks = false

    var allAuthors: [StatsItem]?
    var fetchingAllAuthors = false

    var allReferrers: [StatsItem]?
    var fetchingAllReferrers = false

    var allCountries: [StatsItem]?
    var fetchingAllCountries = false

    var allPublished: [StatsTopPost]?
    var fetchingAllPublished = false
}

class StatsPeriodStore: QueryStore<PeriodStoreState, PeriodQuery> {

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
        case .refreshPeriodOverviewData(let date, let period):
            refreshPeriodOverviewData(date: date, period: period)
        case .receivedAllPostsAndPages(let postsAndPages):
            receivedAllPostsAndPages(postsAndPages)
        case .refreshPostsAndPages(let date, let period):
            refreshPostsAndPages(date: date, period: period)
        case .receivedAllSearchTerms(let searchTerms):
            receivedAllSearchTerms(searchTerms)
        case .refreshSearchTerms(let date, let period):
            refreshSearchTerms(date: date, period: period)
        case .receivedAllVideos(let videos):
            receivedAllVideos(videos)
        case .refreshVideos(let date, let period):
            refreshVideos(date: date, period: period)
        case .receivedAllClicks(let clicks):
            receivedAllClicks(clicks)
        case .refreshClicks(let date, let period):
            refreshClicks(date: date, period: period)
        case .receivedAllAuthors(let authors):
            receivedAllAuthors(authors)
        case .refreshAuthors(let date, let period):
            refreshAuthors(date: date, period: period)
        case .receivedAllReferrers(let referrers):
            receivedAllReferrers(referrers)
        case .refreshReferrers(let date, let period):
            refreshReferrers(date: date, period: period)
        case .receivedAllCountries(let countries):
            receivedAllCountries(countries)
        case .refreshCountries(let date, let period):
            refreshCountries(date: date, period: period)
        case .receivedAllPublished(let published):
            receivedAllPublished(published)
        case .refreshPublished(let date, let period):
            refreshPublished(date: date, period: period)
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
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
                if shouldFetchOverview() {
                    fetchPeriodOverviewData(date: query.date, period: query.period)
                }
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
            }
        }
    }

    func fetchPeriodOverviewData(date: Date, period: StatsPeriodUnit) {

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

    func refreshPeriodOverviewData(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchOverview() else {
            DDLogInfo("Stats Period Overview refresh triggered while one was in progress.")
            return
        }

        fetchPeriodOverviewData(date: date, period: period)
    }

    func fetchAllPostsAndPages(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllPostsAndPages = true

        SiteStatsInformation.statsService()?.retrievePosts(for: date, andUnit: period, withCompletionHandler: { (postsAndPages, error) in
            if error != nil {
                DDLogInfo("Error fetching all Posts and Pages: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all posts and pages.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllPostsAndPages(postsAndPages))
        })
    }

    func refreshPostsAndPages(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPostsAndPages() else {
            DDLogInfo("Stats Period Posts And Pages refresh triggered while one was in progress.")
            return
        }

        fetchAllPostsAndPages(date: date, period: period)
    }

    func fetchAllSearchTerms(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllSearchTerms = true

        SiteStatsInformation.statsService()?.retrieveSearchTerms(for: date, andUnit: period, withCompletionHandler: { (searchTerms, error) in
            if error != nil {
                DDLogInfo("Error fetching all Search Terms: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all search terms.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllSearchTerms(searchTerms))
        })
    }

    func refreshSearchTerms(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchSearchTerms() else {
            DDLogInfo("Stats Period Search Terms refresh triggered while one was in progress.")
            return
        }

        fetchAllSearchTerms(date: date, period: period)
    }

    func fetchAllVideos(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllVideos = true

        SiteStatsInformation.statsService()?.retrieveVideos(for: date, andUnit: period, withCompletionHandler: { (videos, error) in
            if error != nil {
                DDLogInfo("Error fetching all Videos: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all videos.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllVideos(videos))
        })
    }

    func refreshVideos(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchVideos() else {
            DDLogInfo("Stats Period Videos refresh triggered while one was in progress.")
            return
        }

        fetchAllVideos(date: date, period: period)
    }

    func fetchAllClicks(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllClicks = true

        SiteStatsInformation.statsService()?.retrieveClicks(for: date, andUnit: period, withCompletionHandler: { (clicks, error) in
            if error != nil {
                DDLogInfo("Error fetching all Clicks: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all clicks.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllClicks(clicks))
        })
    }

    func refreshClicks(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchClicks() else {
            DDLogInfo("Stats Period Clicks refresh triggered while one was in progress.")
            return
        }

        fetchAllClicks(date: date, period: period)
    }

    func fetchAllAuthors(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllAuthors = true

        SiteStatsInformation.statsService()?.retrieveAuthors(for: date, andUnit: period, withCompletionHandler: { (authors, error) in
            if error != nil {
                DDLogInfo("Error fetching all Authors: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all authors.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllAuthors(authors))
        })
    }

    func refreshAuthors(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchAuthors() else {
            DDLogInfo("Stats Period Authors refresh triggered while one was in progress.")
            return
        }

        fetchAllAuthors(date: date, period: period)
    }

    func fetchAllReferrers(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllReferrers = true

        SiteStatsInformation.statsService()?.retrieveReferrers(for: date, andUnit: period, withCompletionHandler: { (referrers, error) in
            if error != nil {
                DDLogInfo("Error fetching all Referrers: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all referrers.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllReferrers(referrers))
        })
    }

    func refreshReferrers(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchReferrers() else {
            DDLogInfo("Stats Period Referrers refresh triggered while one was in progress.")
            return
        }

        fetchAllReferrers(date: date, period: period)
    }

    func fetchAllCountries(date: Date, period: StatsPeriodUnit) {
        state.fetchingAllCountries = true

        SiteStatsInformation.statsService()?.retrieveCountries(for: date, andUnit: period, withCompletionHandler: { (countries, error) in
            if error != nil {
                DDLogInfo("Error fetching all Countries: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all countries.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllCountries(countries))
        })
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

        state.fetchingAllPublished = true

        statsRemote.getData(for: period, endingOn: date, limit: 0, completion: {
            (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogInfo("Error fetching all Published: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching all published.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAllPublished(published))
        })
    }

    func refreshPublished(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPublished() else {
            DDLogInfo("Stats Period Published refresh triggered while one was in progress.")
            return
        }

        fetchAllPublished(date: date, period: period)
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

    func receivedAllPostsAndPages(_ postsAndPages: StatsGroup?) {
        transaction { state in
            state.allPostsAndPages = postsAndPages?.items as? [StatsItem]
            state.fetchingAllPostsAndPages = false
        }
    }

    func receivedAllSearchTerms(_ searchTerms: StatsGroup?) {
        transaction { state in
            state.allSearchTerms = searchTerms?.items as? [StatsItem] //TODO FIXME reorder this in VM
            state.fetchingAllSearchTerms = false
        }
    }

    func receivedAllVideos(_ videos: StatsGroup?) {
        transaction { state in
            state.allVideos = videos?.items as? [StatsItem]
            state.fetchingAllVideos = false
        }
    }

    func receivedAllClicks(_ clicks: StatsGroup?) {
        transaction { state in
            state.allClicks = clicks?.items as? [StatsItem]
            state.fetchingAllClicks = false
        }
    }

    func receivedAllAuthors(_ authors: StatsGroup?) {
        transaction { state in
            state.allAuthors = authors?.items as? [StatsItem]
            state.fetchingAllAuthors = false
        }
    }

    func receivedAllReferrers(_ referrers: StatsGroup?) {
        transaction { state in
            state.allReferrers = referrers?.items as? [StatsItem]
            state.fetchingAllReferrers = false
        }
    }

    func receivedAllCountries(_ countries: StatsGroup?) {
        transaction { state in
            state.allCountries = countries?.items as? [StatsItem]
            state.fetchingAllCountries = false
        }
    }

    func receivedAllPublished(_ published: StatsPublishedPostsTimeIntervalData?) {
        transaction { state in
            state.fetchingAllPublished = false

            if published != nil {
                state.allPublished = published?.publishedPosts
            }
        }
    }

    // MARK: - Helpers

    func statsRemote() -> StatsServiceRemoteV2? {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
            let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone
            else {
                return nil
        }

        let wpApi = WordPressComRestApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: timeZone)
    }

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    func setAllAsFetchingOverview() {
        state.fetchingSummary = true
        state.fetchingPostsAndPages = true
        state.fetchingReferrers = true
        state.fetchingClicks = true
        state.fetchingPublished = true
        state.fetchingAuthors = true
        state.fetchingSearchTerms = true
        state.fetchingVideos = true
        state.fetchingCountries = true
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

    func getAllPostsAndPages() -> [StatsItem]? {
        return state.allPostsAndPages
    }

    func getAllSearchTerms() -> [StatsItem]? {
        return state.allSearchTerms
    }

    func getAllVideos() -> [StatsItem]? {
        return state.allVideos
    }

    func getAllClicks() -> [StatsItem]? {
        return state.allClicks
    }

    func getAllAuthors() -> [StatsItem]? {
        return state.allAuthors
    }

    func getAllReferrers() -> [StatsItem]? {
        return state.allReferrers
    }

    func getAllCountries() -> [StatsItem]? {
        return state.allCountries
    }

    func getAllPublished() -> [StatsTopPost]? {
        return state.allPublished
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
        return state.fetchingAllPostsAndPages
    }

    var isFetchingSearchTerms: Bool {
        return state.fetchingAllSearchTerms
    }

    var isFetchingVideos: Bool {
        return state.fetchingAllVideos
    }

    var isFetchingClicks: Bool {
        return state.fetchingAllClicks
    }

    var isFetchingAuthors: Bool {
        return state.fetchingAllAuthors
    }

    var isFetchingReferrers: Bool {
        return state.fetchingAllReferrers
    }

    var isFetchingCountries: Bool {
        return state.fetchingAllCountries
    }

    var isFetchingPublished: Bool {
        return state.fetchingAllPublished
    }

}
