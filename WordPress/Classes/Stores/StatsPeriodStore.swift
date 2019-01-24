import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum PeriodAction: Action {
    case receivedPostsAndPages(_ postsAndPages: StatsGroup?)
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

        }, eventsCompletionHandler: { (events, error) in
            if error != nil {
                DDLogInfo("Error fetching events: \(String(describing: error?.localizedDescription))")
            }

        }, postsCompletionHandler: { (postsAndPages, error) in
            if error != nil {
                DDLogInfo("Error fetching posts: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(PeriodAction.receivedPostsAndPages(postsAndPages))
        }, referrersCompletionHandler: { (group, error) in
            if error != nil {
                DDLogInfo("Error fetching referrers: \(String(describing: error?.localizedDescription))")
            }

        }, clicksCompletionHandler: { (group, error) in
            if error != nil {
                DDLogInfo("Error fetching clicks: \(String(describing: error?.localizedDescription))")
            }

        }, countryCompletionHandler: { (group, error) in
            if error != nil {
                DDLogInfo("Error fetching country: \(String(describing: error?.localizedDescription))")
            }

        }, videosCompletionHandler: { (videos, error) in
            if error != nil {
                DDLogInfo("Error fetching videos: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(PeriodAction.receivedVideos(videos))
        }, authorsCompletionHandler: { (group, error) in
            if error != nil {
                DDLogInfo("Error fetching authors: \(String(describing: error?.localizedDescription))")
            }

        }, searchTermsCompletionHandler: { (group, error) in
            if error != nil {
                DDLogInfo("Error fetching search terms: \(String(describing: error?.localizedDescription))")
            }

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

    func receivedVideos(_ videos: StatsGroup?) {
        print("🔴 receivedVideos: ", videos?.items)
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
        state.fetchingVideos = true
    }
}

// MARK: - Public Accessors

extension StatsPeriodStore {

    func getTopPostsAndPages() -> [StatsItem]? {
        return state.topPostsAndPages
    }

    func getTopVideos() -> [StatsItem]? {
        return state.topVideos
    }

    var isFetching: Bool {
        return state.fetchingPostsAndPages ||
            state.fetchingVideos
    }

}
