import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum InsightAction: Action {
    case receivedLatestPostSummary(_ latestPostSummary: StatsLatestPostSummary?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTime?)
    case receivedMostPopularStats(_ mostPopularStats: StatsInsights?)
    case refreshInsights()
}

enum InsightQuery {
    case insights
}

struct InsightStoreState {
    var latestPostSummary: StatsLatestPostSummary?
    var fetchingLatestPostSummary = false
    var allTimeStats: StatsAllTime?
    var fetchingAllTimeStats = false
    var mostPopularStats: StatsInsights?
    var fetchingMostPopularStats = false
}

class StatsInsightsStore: QueryStore<InsightStoreState, InsightQuery> {

    init() {
        super.init(initialState: InsightStoreState())
    }

    override func onDispatch(_ action: Action) {

        guard let insightAction = action as? InsightAction else {
            return
        }

        switch insightAction {
        case .receivedLatestPostSummary(let latestPostSummary):
            receivedLatestPostSummary(latestPostSummary)
        case .receivedAllTimeStats(let allTimeStats):
            receivedAllTimeStats(allTimeStats)
        case .receivedMostPopularStats(let mostPopularStats):
            receivedMostPopularStats(mostPopularStats)
        case .refreshInsights:
            refreshInsights()
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

}

// MARK: - Private Methods

private extension StatsInsightsStore {

    func processQueries() {

        guard !activeQueries.isEmpty && shouldFetch() else {
            return
        }

        fetchInsights()
    }

    func fetchInsights() {

        state.fetchingLatestPostSummary = true
        state.fetchingAllTimeStats = true
        state.fetchingMostPopularStats = true

        SiteStatsInformation.statsService()?.retrieveInsightsStats(allTimeStatsCompletionHandler: { (allTimeStats, error) in
            if error != nil {
                DDLogInfo("Error fetching all time stats: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTimeStats(allTimeStats))
        }, insightsCompletionHandler: { (mostPopularStats, error) in
            if error != nil {
                DDLogInfo("Error fetching most popular stats: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedMostPopularStats(mostPopularStats))
        }, todaySummaryCompletionHandler: { (todaySummary, error) in

        }, latestPostSummaryCompletionHandler: { (latestPostSummary, error) in
            if error != nil {
                DDLogInfo("Error fetching latest post summary: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedLatestPostSummary(latestPostSummary))
        }, commentsAuthorCompletionHandler: { (commentsAuthors, error) in

        }, commentsPostsCompletionHandler: { (commentsPosts, error) in

        }, tagsCategoriesCompletionHandler: { (tagsCategories, error) in

        }, followersDotComCompletionHandler: { (followersDotCom, error) in

        }, followersEmailCompletionHandler: { (followersEmail, error) in

        }, publicizeCompletionHandler: { (publicize, error) in

        }, streakCompletionHandler: { (statsStreak, error) in

        }, progressBlock: { (numberOfFinishedOperations, totalNumberOfOperations) in

        }, andOverallCompletionHandler: {

        })
    }

    func refreshInsights() {
        guard shouldFetch() else {
            DDLogInfo("Stats Insights refresh triggered while one was in progress.")
            return
        }

        fetchInsights()
    }

    func receivedLatestPostSummary(_ latestPostSummary: StatsLatestPostSummary?) {
        transaction { state in
            state.latestPostSummary = latestPostSummary
            state.fetchingLatestPostSummary = false
        }
    }

    func receivedAllTimeStats(_ allTimeStats: StatsAllTime?) {
        transaction { state in
            state.allTimeStats = allTimeStats
            state.fetchingAllTimeStats = false
        }
    }

    func receivedMostPopularStats(_ mostPopularStats: StatsInsights?) {
        transaction { state in
            state.mostPopularStats = mostPopularStats
            state.fetchingMostPopularStats = false
        }
    }

    func shouldFetch() -> Bool {
        return !isFetching
    }

}

// MARK: - Public Accessors

extension StatsInsightsStore {

    func getLatestPostSummary() -> StatsLatestPostSummary? {
        return state.latestPostSummary
    }

    func getAllTimeStats() -> StatsAllTime? {
        return state.allTimeStats
    }

    func getMostPopularStats() -> StatsInsights? {
        return state.mostPopularStats
    }

    var isFetching: Bool {
        return state.fetchingLatestPostSummary || state.fetchingAllTimeStats || state.fetchingMostPopularStats
    }
}
