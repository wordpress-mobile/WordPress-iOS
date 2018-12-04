import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum InsightAction: Action {
    case receivedLatestPostSummary(_ latestPostSummary: StatsLatestPostSummary?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTime?)
    case receivedMostPopularStats(_ mostPopularStats: StatsInsights?)
    case receivedDotComFollowers(total: String?)
    case receivedEmailFollowers(total: String?)
    case receivedPublicize(items: [StatsItem]?)
    case receivedTodaysStats(_ todaysStats: StatsSummary?)
    case receivedPostingActivity(_ postingActivity: StatsStreak?)
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
    var totalDotComFollowers: String?
    var fetchingDotComFollowers = false
    var totalEmailFollowers: String?
    var fetchingEmailFollowers = false
    var publicizeItems: [StatsItem]?
    var fetchingPublicize = false
    var todaysStats: StatsSummary?
    var fetchingTodaysStats = false
    var postingActivity: StatsStreak?
    var fetchingPostingActivity = false
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
        case .receivedDotComFollowers(let total):
            receivedDotComFollowers(total: total)
        case .receivedEmailFollowers(let total):
            receivedEmailFollowers(total: total)
        case .receivedPublicize(let items):
            receivedPublicize(items: items)
        case .receivedTodaysStats(let todaysStats):
            receivedTodaysStats(todaysStats)
        case .receivedPostingActivity(let postingActivity):
            receivedPostingActivity(postingActivity)
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
        state.fetchingDotComFollowers = true
        state.fetchingEmailFollowers = true
        state.fetchingPublicize = true
        state.fetchingTodaysStats = true
        state.fetchingPostingActivity = true

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
            if error != nil {
                DDLogInfo("Error fetching today summary: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedTodaysStats(todaySummary))
        }, latestPostSummaryCompletionHandler: { (latestPostSummary, error) in
            if error != nil {
                DDLogInfo("Error fetching latest post summary: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedLatestPostSummary(latestPostSummary))
        }, commentsAuthorCompletionHandler: { (commentsAuthors, error) in

        }, commentsPostsCompletionHandler: { (commentsPosts, error) in

        }, tagsCategoriesCompletionHandler: { (tagsCategories, error) in

        }, followersDotComCompletionHandler: { (followersDotCom, error) in
            if error != nil {
                DDLogInfo("Error fetching dot com followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(total: followersDotCom?.totalCount))
        }, followersEmailCompletionHandler: { (followersEmail, error) in
            if error != nil {
                DDLogInfo("Error fetching email followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(total: followersEmail?.totalCount))
        }, publicizeCompletionHandler: { (publicize, error) in
            if error != nil {
                DDLogInfo("Error fetching publicize: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedPublicize(items: publicize?.items as? [StatsItem]))
        }, streakCompletionHandler: { (statsStreak, error) in
            if error != nil {
                DDLogInfo("Error fetching stats streak: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedPostingActivity(statsStreak))
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

    func receivedDotComFollowers(total: String?) {
        transaction { state in
            state.totalDotComFollowers = total
            state.fetchingDotComFollowers = false
        }
    }

    func receivedEmailFollowers(total: String?) {
        transaction { state in
            state.totalEmailFollowers = total
            state.fetchingEmailFollowers = false
        }
    }

    func receivedPublicize(items: [StatsItem]?) {
        transaction { state in
            state.publicizeItems = items
            state.fetchingPublicize = false
        }
    }

    func receivedTodaysStats(_ todaysStats: StatsSummary?) {
        transaction { state in
            state.todaysStats = todaysStats
            state.fetchingTodaysStats = false
        }
    }

    func receivedPostingActivity(_ postingActivity: StatsStreak?) {
        transaction { state in
            state.postingActivity = postingActivity
            state.fetchingPostingActivity = false
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

    func getTotalDotComFollowers() -> String? {
        // TODO: When the API is able to, return the actual value (not a String).
        return state.totalDotComFollowers == "0" ? "" : state.totalDotComFollowers
    }

    func getTotalEmailFollowers() -> String? {
        // TODO: When the API is able to, return the actual value (not a String).
        return state.totalEmailFollowers == "0" ? "" : state.totalEmailFollowers
    }

    func getTotalPublicizeFollowers() -> String? {
        // TODO: When the API is able to, return the actual value (not a String)
        // total of all publicize items.
        // For now, we'll just show a bogus number.
        return "666,666,666"
    }

    func getPublicize() -> [StatsItem]? {
        return state.publicizeItems
    }

    func getTodaysStats() -> StatsSummary? {
        return state.todaysStats
    }

    func getMonthlyPostingActivityFor(date: Date) -> [PostingActivityDayData] {

        var monthData = [PostingActivityDayData]()
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: date.normalizedDate())

        // Add every day in the month to the array, seeding with 0 counts.
        guard let dayRange = Calendar.current.range(of: .day, in: .month, for: date) else {
            return monthData
        }

        dayRange.forEach { day in
            let components = DateComponents(year: dateComponents.year, month: dateComponents.month, day: day)
            guard let date = Calendar.current.date(from: components) else {
                return
            }

            monthData.append(PostingActivityDayData(date: date, count: 0))
        }

        // If there is no posting activity at all, return.
        guard let allPostingActivity = state.postingActivity?.items else {
            return monthData
        }

        // If the posting occurred in the requested month, increment the count for that day.
        allPostingActivity.forEach { postingActivity in
            let postDate = postingActivity.date.normalizedDate()
            if let dayIndex = monthData.index(where: { $0.date == postDate }) {
                monthData[dayIndex].count += 1
            }
        }

        return monthData
    }

    var isFetching: Bool {
        return state.fetchingLatestPostSummary ||
            state.fetchingAllTimeStats ||
            state.fetchingMostPopularStats ||
            state.fetchingDotComFollowers ||
            state.fetchingEmailFollowers ||
            state.fetchingPublicize ||
            state.fetchingTodaysStats ||
            state.fetchingPostingActivity
    }

}
