import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum PeriodAction: Action {

    // Period overview

    case receivedPostsAndPages(_ postsAndPages: StatsGroup?)
    case receivedPublished(_ published: StatsGroup?)
    case receivedReferrers(_ referrers: StatsGroup?)
    case receivedClicks(_ clicks: StatsGroup?)
    case receivedAuthors(_ authors: StatsGroup?)
    case receivedSearchTerms(_ searchTerms: StatsGroup?)
    case receivedVideos(_ videos: StatsGroup?)
    case receivedCountries(_ countries: StatsGroup?)
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

    case receivedAllPublished()
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

    var topPostsAndPages: [StatsItem]?
    var fetchingPostsAndPages = false

    var topReferrers: [StatsItem]?
    var fetchingReferrers = false

    var topClicks: [StatsItem]?
    var fetchingClicks = false

    var topPublished: [StatsItem]?
    var fetchingPublished = false

    var topAuthors: [StatsItem]?
    var fetchingAuthors = false

    var topSearchTerms: [StatsItem]?
    var fetchingSearchTerms = false

    var topCountries: [StatsItem]?
    var fetchingCountries = false

    var topVideos: [StatsItem]?
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

    var allPublished: [StatsItem]?
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
        case .receivedAllPublished:
            receivedAllPublished()
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

        // remove
        fetchAllPublished(date: date, period: period)

        setAllAsFetchingOverview()

        SiteStatsInformation.statsService()?.retrieveAllStats(for: date, unit: period, withVisitsCompletionHandler: { (visits, error) in
            if error != nil {
                DDLogInfo("Error fetching visits: \(String(describing: error?.localizedDescription))")
            }

        }, eventsCompletionHandler: { (published, error) in
            if error != nil {
                DDLogInfo("Error fetching events: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching published.")
            self.actionDispatcher.dispatch(PeriodAction.receivedPublished(published))
        }, postsCompletionHandler: { (postsAndPages, error) in
            if error != nil {
                DDLogInfo("Error fetching posts: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching posts and pages.")
            self.actionDispatcher.dispatch(PeriodAction.receivedPostsAndPages(postsAndPages))
        }, referrersCompletionHandler: { (referrers, error) in
            if error != nil {
                DDLogInfo("Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching referrers.")
            self.actionDispatcher.dispatch(PeriodAction.receivedReferrers(referrers))
        }, clicksCompletionHandler: { (clicks, error) in
            if error != nil {
                DDLogInfo("Error fetching clicks: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching clicks.")
            self.actionDispatcher.dispatch(PeriodAction.receivedClicks(clicks))
        }, countryCompletionHandler: { (countries, error) in
            if error != nil {
                DDLogInfo("Error fetching countries: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching countries.")
            self.actionDispatcher.dispatch(PeriodAction.receivedCountries(countries))

        }, videosCompletionHandler: { (videos, error) in
            if error != nil {
                DDLogInfo("Error fetching videos: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching videos.")
            self.actionDispatcher.dispatch(PeriodAction.receivedVideos(videos))
        }, authorsCompletionHandler: { (authors, error) in
            if error != nil {
                DDLogInfo("Error fetching authors: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching authors.")
            self.actionDispatcher.dispatch(PeriodAction.receivedAuthors(authors))
        }, searchTermsCompletionHandler: { (searchTerms, error) in
            if error != nil {
                DDLogInfo("Error fetching search terms: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Stats: Finished fetching search terms.")
            self.actionDispatcher.dispatch(PeriodAction.receivedSearchTerms(searchTerms))
        }, progressBlock: { (numberOfFinishedOperations, totalNumberOfOperations) in

        }, andOverallCompletionHandler: {

        })

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
        state.fetchingAllPublished = true

        // TODO: replace with api call when fetch all published is supported.
        actionDispatcher.dispatch(PeriodAction.receivedAllPublished())
    }

    func refreshPublished(date: Date, period: StatsPeriodUnit) {
        guard shouldFetchPublished() else {
            DDLogInfo("Stats Period Published refresh triggered while one was in progress.")
            return
        }

        fetchAllPublished(date: date, period: period)
    }

    // MARK: - Receive data methods

    func receivedPostsAndPages(_ postsAndPages: StatsGroup?) {
        transaction { state in
            state.topPostsAndPages = postsAndPages?.items as? [StatsItem]
            state.fetchingPostsAndPages = false
        }
    }

    func receivedReferrers(_ referrers: StatsGroup?) {
        transaction { state in
            state.topReferrers = referrers?.items as? [StatsItem]
            state.fetchingReferrers = false
        }
    }

    func receivedClicks(_ clicks: StatsGroup?) {
        transaction { state in
            state.topClicks = clicks?.items as? [StatsItem]
            state.fetchingClicks = false
        }
    }

    func receivedAuthors(_ authors: StatsGroup?) {
        transaction { state in
            state.topAuthors = authors?.items as? [StatsItem]
            state.fetchingAuthors = false
        }
    }

    func receivedPublished(_ published: StatsGroup?) {
        transaction { state in
            state.topPublished = published?.items as? [StatsItem]
            state.fetchingPublished = false
        }
    }

    func receivedSearchTerms(_ searchTerms: StatsGroup?) {
        transaction { state in
            state.topSearchTerms = reorderSearchTerms(searchTerms)
            state.fetchingSearchTerms = false
        }
    }

    func receivedVideos(_ videos: StatsGroup?) {
        transaction { state in
            state.topVideos = videos?.items as? [StatsItem]
            state.fetchingVideos = false
        }
    }

    func receivedCountries(_ countries: StatsGroup?) {
        transaction { state in
            state.topCountries = countries?.items as? [StatsItem]
            state.fetchingCountries = false
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
            state.allSearchTerms = reorderSearchTerms(searchTerms)
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

    func receivedAllPublished() {
        transaction { state in
            // TODO: replace with real allPublished when API supports it.
            state.allPublished = state.topPublished
            state.fetchingAllPublished = false
        }
    }

    // MARK: - Helpers

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    func setAllAsFetchingOverview() {
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

    /// This method modifies the 'Unknown search terms' row and changes its location in the array.
    /// - Find the 'Unknown search terms' row
    /// - Change the label
    /// - Remove the row from the array
    /// - Insert the row at the beginning of the array
    /// NOTE: When the backend is updated, maybe it will return the unknown row at the top
    /// of the array, making this unnecessary.
    ///
    func reorderSearchTerms(_ searchTerms: StatsGroup?) -> [StatsItem]? {
        guard var searchTerms = searchTerms?.items as? [StatsItem] else {
            return nil
        }

        // This labelToFind matches that in WPStatsServiceRemote:operationForSearchTermsForDate
        let labelToFind = NSLocalizedString("Unknown Search Terms", comment: "N/A. Not visible to users.")

        // Find the row in the array
        guard let unknownSearchTermRow = searchTerms.first(where: ({ $0.label == labelToFind }))  else {
            return searchTerms
        }

        // Capitalize only the firt letter of the label
        unknownSearchTermRow.label = NSLocalizedString("Unknown search terms", comment: "Search Terms label for 'unknown search terms'.")

        // Remove the row from the array
        searchTerms = searchTerms.filter { $0 != unknownSearchTermRow }

        // And add it back at the top
        searchTerms.insert(unknownSearchTermRow, at: 0)

        return searchTerms
    }

}

// MARK: - Public Accessors

extension StatsPeriodStore {

    func getTopPostsAndPages() -> [StatsItem]? {
        return state.topPostsAndPages
    }

    func getTopReferrers() -> [StatsItem]? {
        return state.topReferrers
    }

    func getTopClicks() -> [StatsItem]? {
        return state.topClicks
    }

    func getTopPublished() -> [StatsItem]? {
        return state.topPublished
    }

    func getTopAuthors() -> [StatsItem]? {
        return state.topAuthors
    }

    func getTopSearchTerms() -> [StatsItem]? {
        return state.topSearchTerms
    }

    func getTopVideos() -> [StatsItem]? {
        return state.topVideos
    }

    func getTopCountries() -> [StatsItem]? {
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

    func getAllPublished() -> [StatsItem]? {
        return state.allPublished
    }

    var isFetchingOverview: Bool {
        return state.fetchingPostsAndPages ||
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
