import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum InsightAction: Action {
    case receivedLatestPostSummary(_ latestPostSummary: StatsLatestPostSummary?)
}

enum InsightQuery {
    case insights()
}

struct InsightStoreState {
    var latestPostSummary: StatsLatestPostSummary?
    var fetchingLatestPostSummary = false
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

        SiteStatsInformation.statsService()?.retrieveInsightsStats(allTimeStatsCompletionHandler: { (allTimeStats, error) in

        }, insightsCompletionHandler: { (mostPopularStats, error) in

        }, todaySummaryCompletionHandler: { (todaySummary, error) in

        }, latestPostSummaryCompletionHandler: { (latestPostSummary, error) in
            if error != nil {
                DDLogDebug("Error fetching latest post summary: \(String(describing: error?.localizedDescription))")
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

    func receivedLatestPostSummary(_ latestPostSummary: StatsLatestPostSummary?) {
        transaction { state in
            state.latestPostSummary = latestPostSummary
            state.fetchingLatestPostSummary = false
        }
    }

    func shouldFetch() -> Bool {
        return !isFetching()
    }

    func isFetching() -> Bool {
        return state.fetchingLatestPostSummary
    }

}

// MARK: - Selectors

extension StatsInsightsStore {

    func getLatestPostSummary() -> StatsLatestPostSummary? {
        return state.latestPostSummary
    }

}
