import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum InsightAction: Action {
    case receivedLatestPostSummary(_ latestPostSummary: StatsLatestPostSummary?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTime?)
    case receivedMostPopularStats(_ mostPopularStats: StatsInsights?)
    case receivedDotComFollowers(_ followerStats: StatsGroup?)
    case receivedEmailFollowers(_ followerStats: StatsGroup?)
    case receivedCommentsAuthors(_ commentsAuthors: StatsGroup?)
    case receivedCommentsPosts(_ commentsPosts: StatsGroup?)
    case receivedPublicize(items: [StatsItem]?)
    case receivedTodaysStats(_ todaysStats: StatsSummary?)
    case receivedPostingActivity(_ postingActivity: StatsStreak?)
    case receivedTagsAndCategories(_ tagsAndCategories: StatsGroup?)
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
    var topDotComFollowers: [StatsItem]?
    var fetchingDotComFollowers = false

    var totalEmailFollowers: String?
    var topEmailFollowers: [StatsItem]?
    var fetchingEmailFollowers = false

    var topCommentsAuthors: [StatsItem]?
    var fetchingCommentsAuthors = false

    var topCommentsPosts: [StatsItem]?
    var fetchingCommentsPosts = false

    var publicizeItems: [StatsItem]?
    var fetchingPublicize = false

    var todaysStats: StatsSummary?
    var fetchingTodaysStats = false

    var postingActivity: StatsStreak?
    var fetchingPostingActivity = false

    var topTagsAndCategories: [StatsItem]?
    var fetchingTagsAndCategories = false
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
        case .receivedDotComFollowers(let followerStats):
            receivedDotComFollowers(followerStats)
        case .receivedEmailFollowers(let followerStats):
            receivedEmailFollowers(followerStats)
        case .receivedCommentsAuthors(let commentsAuthors):
            receivedCommentsAuthors(commentsAuthors)
        case .receivedCommentsPosts(let commentsPosts):
            receivedCommentsPosts(commentsPosts)
        case .receivedPublicize(let items):
            receivedPublicize(items: items)
        case .receivedTodaysStats(let todaysStats):
            receivedTodaysStats(todaysStats)
        case .receivedPostingActivity(let postingActivity):
            receivedPostingActivity(postingActivity)
        case .receivedTagsAndCategories(let tagsAndCategories):
            receivedTagsAndCategories(tagsAndCategories)
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

        setAllAsFetching()

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
            if error != nil {
                DDLogInfo("Error fetching comments authors: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedCommentsAuthors(commentsAuthors))
        }, commentsPostsCompletionHandler: { (commentsPosts, error) in
            if error != nil {
                DDLogInfo("Error fetching comments posts: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedCommentsPosts(commentsPosts))
        }, tagsCategoriesCompletionHandler: { (tagsCategories, error) in
            if error != nil {
                DDLogInfo("Error fetching tags and categories: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedTagsAndCategories(tagsCategories))
        }, followersDotComCompletionHandler: { (followersDotCom, error) in
            if error != nil {
                DDLogInfo("Error fetching dot com followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(followersDotCom))
        }, followersEmailCompletionHandler: { (followersEmail, error) in
            if error != nil {
                DDLogInfo("Error fetching email followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(followersEmail))
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

    func receivedDotComFollowers(_ followerStats: StatsGroup?) {
        transaction { state in
            state.topDotComFollowers = followerStats?.items as? [StatsItem]
            state.totalDotComFollowers = followerStats?.totalCount
            state.fetchingDotComFollowers = false
        }
    }

    func receivedEmailFollowers(_ followerStats: StatsGroup?) {
        transaction { state in
            state.topEmailFollowers = followerStats?.items as? [StatsItem]
            state.totalEmailFollowers = followerStats?.totalCount
            state.fetchingEmailFollowers = false
        }
    }

    func receivedCommentsAuthors(_ commentsAuthors: StatsGroup?) {
        transaction { state in
            state.topCommentsAuthors = commentsAuthors?.items as? [StatsItem]
            state.fetchingCommentsAuthors = false
        }
    }

    func receivedCommentsPosts(_ commentsPosts: StatsGroup?) {
        transaction { state in
            state.topCommentsPosts = commentsPosts?.items as? [StatsItem]
            state.fetchingCommentsPosts = false
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

    func receivedTagsAndCategories(_ tagsAndCategories: StatsGroup?) {
        transaction { state in
            state.topTagsAndCategories = tagsAndCategories?.items as? [StatsItem]
            state.fetchingTagsAndCategories = false
        }
    }

    func shouldFetch() -> Bool {
        return !isFetching
    }

    func setAllAsFetching() {
        state.fetchingLatestPostSummary = true
        state.fetchingAllTimeStats = true
        state.fetchingMostPopularStats = true
        state.fetchingDotComFollowers = true
        state.fetchingEmailFollowers = true
        state.fetchingPublicize = true
        state.fetchingTodaysStats = true
        state.fetchingPostingActivity = true
        state.fetchingCommentsAuthors = true
        state.fetchingCommentsPosts = true
        state.fetchingTagsAndCategories = true
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

    func getTopDotComFollowers() -> [StatsItem]? {
        return state.topDotComFollowers
    }

    func getTotalDotComFollowers() -> String? {
        // TODO: When the API is able to, return the actual value (not a String).
        return state.totalDotComFollowers == "0" ? "" : state.totalDotComFollowers
    }

    func getTopEmailFollowers() -> [StatsItem]? {
        return state.topEmailFollowers
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

    func getTopCommentsAuthors() -> [StatsItem]? {
        return state.topCommentsAuthors
    }

    func getTopCommentsPosts() -> [StatsItem]? {
        return state.topCommentsPosts
    }

    func getPublicize() -> [StatsItem]? {
        return state.publicizeItems
    }

    func getTodaysStats() -> StatsSummary? {
        return state.todaysStats
    }

    func getTopTagsAndCategories() -> [StatsItem]? {
        return state.topTagsAndCategories
    }

    /// Summarizes the daily posting count for the month in the given date.
    /// Returns an array containing every day of the month and associated post count.
    ///
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

    func getYearlyPostingActivityFrom(date: Date) -> [[PostingActivityDayData]] {
        var monthsData = [[PostingActivityDayData]]()

        // Get last 12 months, in ascending order.
        for month in (0...11).reversed() {
            if let monthDate = Calendar.current.date(byAdding: .month, value: -month, to: Date()) {
                monthsData.append(getMonthlyPostingActivityFor(date: monthDate))
            }
        }

        return monthsData
    }

    var isFetching: Bool {
        return state.fetchingLatestPostSummary ||
            state.fetchingAllTimeStats ||
            state.fetchingMostPopularStats ||
            state.fetchingDotComFollowers ||
            state.fetchingEmailFollowers ||
            state.fetchingPublicize ||
            state.fetchingTodaysStats ||
            state.fetchingPostingActivity ||
            state.fetchingCommentsAuthors ||
            state.fetchingCommentsPosts ||
            state.fetchingTagsAndCategories
    }

}
