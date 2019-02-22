import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum PeriodAction: Action {
    case receivedPostsAndPages(_ postsAndPages: StatsGroup?)
    case receivedPublished(_ published: StatsGroup?)
    case receivedReferrers(_ referrers: StatsGroup?)
    case receivedClicks(_ clicks: StatsGroup?)
    case receivedAuthors(_ authors: StatsGroup?)
    case receivedSearchTerms(_ searchTerms: StatsGroup?)
    case receivedVideos(_ videos: StatsGroup?)
    case refreshPeriodData(date: Date, period: StatsPeriodUnit)
}

enum PeriodQuery {
    case periods(date: Date, period: StatsPeriodUnit)

    var date: Date {
        switch self {
        case .periods(let date, _):
            return date
        }
    }

    var period: StatsPeriodUnit {
        switch self {
        case .periods( _, let period):
            return period
        }
    }
}

struct PeriodStoreState {
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

    var topVideos: [StatsItem]?
    var fetchingVideos = false
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
        case .refreshPeriodData(let date, let period):
            refreshPeriodData(date: date, period: period)
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

        guard !activeQueries.isEmpty && shouldFetch() else {
            return
        }

        runPeriodsQuery()
    }

    func runPeriodsQuery() {
        let periodsQuery = activeQueries
            .filter {
                if case .periods = $0 {
                    return true
                } else {
                    return false
                }
            }.first

        if let periodsQuery = periodsQuery {
            fetchPeriodData(date: periodsQuery.date, period: periodsQuery.period)
        }
    }

    func fetchPeriodData(date: Date, period: StatsPeriodUnit) {

        setAllAsFetching()

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
        }, countryCompletionHandler: { (group, error) in
            if error != nil {
                DDLogInfo("Error fetching country: \(String(describing: error?.localizedDescription))")
            }

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

    func refreshPeriodData(date: Date, period: StatsPeriodUnit) {
        guard shouldFetch() else {
            DDLogInfo("Stats Period refresh triggered while one was in progress.")
            return
        }

        fetchPeriodData(date: date, period: period)
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

    // MARK: - Helpers

    func shouldFetch() -> Bool {
        return !isFetching
    }

    func setAllAsFetching() {
        state.fetchingPostsAndPages = true
        state.fetchingReferrers = true
        state.fetchingClicks = true
        state.fetchingPublished = true
        state.fetchingAuthors = true
        state.fetchingSearchTerms = true
        state.fetchingVideos = true
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

    var isFetching: Bool {
        return state.fetchingPostsAndPages ||
            state.fetchingReferrers ||
            state.fetchingClicks ||
            state.fetchingPublished ||
            state.fetchingAuthors ||
            state.fetchingSearchTerms ||
            state.fetchingVideos
    }

}
