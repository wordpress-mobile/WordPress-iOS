import Foundation
import WordPressKit
import WordPressFlux
import WordPressComStatsiOS

enum InsightAction: Action {
    case receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?)
    case receivedAnnualAndMostPopularTimeStats(_ annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?)
    case receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?)
    case receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?)
    case receivedPublicize(_ publicizeStats: StatsPublicizeInsight?)
    case receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?)
    case receivedTodaysStats(_ todaysStats: StatsTodayInsight?)
    case receivedPostingActivity(_ postingActivity: StatsStreak?)
    case receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?)
    case refreshInsights()
}

enum InsightQuery {
    case insights
}

struct InsightStoreState {
    var lastPostInsight: StatsLastPostInsight?
    var fetchingLastPostInsight = false

    var allTimeStats: StatsAllTimesInsight?
    var fetchingAllTimeStats = false

    var annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?
    var fetchingAnnualAndMostPopularTime = false

    var dotComFollowers: StatsDotComFollowersInsight?
    var fetchingDotComFollowers = false

    var emailFollowers: StatsEmailFollowersInsight?
    var fetchingEmailFollowers = false

    var publicizeFollowers: StatsPublicizeInsight?
    var fetchingPublicize = false

    var topCommentsInsight: StatsCommentsInsight?
    var fetchingCommentsInsight = false

    var todaysStats: StatsTodayInsight?
    var fetchingTodaysStats = false

    var postingActivity: StatsStreak?
    var fetchingPostingActivity = false

    var topTagsAndCategories: StatsTagsAndCategoriesInsight?
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
        case .receivedLastPostInsight(let lastPostInsight):
            receivedLastPostInsight(lastPostInsight)
        case .receivedAllTimeStats(let allTimeStats):
            receivedAllTimeStats(allTimeStats)
        case .receivedAnnualAndMostPopularTimeStats(let mostPopularStats):
            receivedAnnualAndMostPopularTimeStats(mostPopularStats)
        case .receivedDotComFollowers(let followerStats):
            receivedDotComFollowers(followerStats)
        case .receivedEmailFollowers(let followerStats):
            receivedEmailFollowers(followerStats)
        case .receivedCommentsInsight(let commentsInsight):
            receivedCommentsInsight(commentsInsight)
        case .receivedPublicize(let items):
            receivedPublicizeFollowers(items)
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

        let api = apiService(for: SiteStatsInformation.sharedInstance.siteID!.intValue)

        api.getInsight { (lastPost: StatsLastPostInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching last posts insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedLastPostInsight(lastPost))
        }

        api.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all time insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTimeStats(allTimesStats))
        }

        api.getInsight { (wpComFollowers: StatsDotComFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching WP.com followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(wpComFollowers))
        }

        api.getInsight { (emailFollowers: StatsEmailFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching email followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(emailFollowers))
        }

        api.getInsight { (publicizeInsight: StatsPublicizeInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching publicize insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedPublicize(publicizeInsight))
        }

        api.getInsight { (annualAndTime: StatsAnnualAndMostPopularTimeInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching most popular time: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAnnualAndMostPopularTimeStats(annualAndTime))
        }

        api.getInsight { (todayInsight: StatsTodayInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching today's insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedTodaysStats(todayInsight))
        }

        api.getInsight { (commentsInsights: StatsCommentsInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching comment insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedCommentsInsight(commentsInsights))
        }

        api.getInsight { (tagsAndCategoriesInsight: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching tags and categories insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedTagsAndCategories(tagsAndCategoriesInsight))
        }

        SiteStatsInformation.statsService()?.retrieveInsightsStats(
        allTimeStatsCompletionHandler: nil,
        insightsCompletionHandler: nil,
        todaySummaryCompletionHandler: nil,
        latestPostSummaryCompletionHandler: nil,
        commentsAuthorCompletionHandler: nil,
        commentsPostsCompletionHandler: nil,
        tagsCategoriesCompletionHandler: nil,
        followersDotComCompletionHandler: nil,
        followersEmailCompletionHandler: nil,
        publicizeCompletionHandler: nil,
        streakCompletionHandler: { (statsStreak, error) in
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

    func receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?) {
        transaction { state in
            state.lastPostInsight = lastPostInsight
            state.fetchingLastPostInsight = false
        }
    }

    func receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?) {
        transaction { state in
            state.allTimeStats = allTimeStats
            state.fetchingAllTimeStats = false
        }
    }

    func receivedAnnualAndMostPopularTimeStats(_ mostPopularStats: StatsAnnualAndMostPopularTimeInsight?) {
        transaction { state in
            state.annualAndMostPopularTime = mostPopularStats
            state.fetchingAnnualAndMostPopularTime = false
        }
    }

    func receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?) {
        transaction { state in
            state.dotComFollowers = followerStats
            state.fetchingDotComFollowers = false
        }
    }

    func receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?) {
        transaction { state in
            state.emailFollowers = followerStats
            state.fetchingEmailFollowers = false
        }
    }

    func receivedPublicizeFollowers(_ followerStats: StatsPublicizeInsight?) {
        transaction { state in
            state.publicizeFollowers = followerStats
            state.fetchingPublicize = false
        }
    }

    func receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?) {
        transaction { state in
            state.topCommentsInsight = commentsInsight
            state.fetchingCommentsInsight = false
        }
    }

    func receivedTodaysStats(_ todaysStats: StatsTodayInsight?) {
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

    func receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?) {
        transaction { state in
            state.topTagsAndCategories = tagsAndCategories
            state.fetchingTagsAndCategories = false
        }
    }

    func shouldFetch() -> Bool {
        return !isFetching
    }

    func setAllAsFetching() {
        state.fetchingLastPostInsight = true
        state.fetchingAllTimeStats = true
        state.fetchingAnnualAndMostPopularTime = true
        state.fetchingDotComFollowers = true
        state.fetchingEmailFollowers = true
        state.fetchingPublicize = true
        state.fetchingTodaysStats = true
        state.fetchingPostingActivity = true
        state.fetchingCommentsInsight = true
        state.fetchingTagsAndCategories = true
    }

}

// MARK: - Public Accessors

extension StatsInsightsStore {

    func getLastPostInsight() -> StatsLastPostInsight? {
        return state.lastPostInsight
    }

    func getAllTimeStats() -> StatsAllTimesInsight? {
        return state.allTimeStats
    }

    func getAnnualAndMostPopularTime() -> StatsAnnualAndMostPopularTimeInsight? {
        return state.annualAndMostPopularTime
    }

    func getDotComFollowers() -> StatsDotComFollowersInsight? {
        return state.dotComFollowers
    }

    func getEmailFollowers() -> StatsEmailFollowersInsight? {
        return state.emailFollowers
    }

    func getPublicize() -> StatsPublicizeInsight? {
        return state.publicizeFollowers
    }

    func getTopCommentsInsight() -> StatsCommentsInsight? {
        return state.topCommentsInsight
    }

    func getTodaysStats() -> StatsTodayInsight? {
        return state.todaysStats
    }

    func getTopTagsAndCategories() -> StatsTagsAndCategoriesInsight? {
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
        return
            state.fetchingLastPostInsight ||
            state.fetchingAllTimeStats ||
            state.fetchingAnnualAndMostPopularTime ||
            state.fetchingDotComFollowers ||
            state.fetchingEmailFollowers ||
            state.fetchingPublicize ||
            state.fetchingTodaysStats ||
            state.fetchingPostingActivity ||
            state.fetchingCommentsInsight ||
            state.fetchingTagsAndCategories
    }

    private func apiService(`for` site: Int) -> StatsServiceRemoteV2 {
        let api = WordPressComRestApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())

        return StatsServiceRemoteV2(wordPressComRestApi: api, siteID: site, siteTimezone: SiteStatsInformation.sharedInstance.siteTimeZone!)
    }

}
