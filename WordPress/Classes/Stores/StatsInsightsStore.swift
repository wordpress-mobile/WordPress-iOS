import Foundation
import WordPressKit
import WordPressFlux
import WordPressComStatsiOS

enum InsightAction: Action {

    // Insights overview
    case receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?)
    case receivedAnnualAndMostPopularTimeStats(_ annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?)
    case receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?)
    case receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?)
    case receivedPublicize(_ publicizeStats: StatsPublicizeInsight?)
    case receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?)
    case receivedTodaysStats(_ todaysStats: StatsTodayInsight?)
    case receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?)
    case receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?)
    case refreshInsights()

    // Insights details
    case receivedAllDotComFollowers(_ allDotComFollowers: StatsGroup?)
    case receivedAllEmailFollowers(_ allDotComFollowers: StatsGroup?)
    case refreshFollowers()
}

enum InsightQuery {
    case insights
    case allFollowers
}

struct InsightStoreState {

    // Insights overview

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

    var postingActivity: StatsPostingStreakInsight?
    var fetchingPostingActivity = false

    var topTagsAndCategories: StatsTagsAndCategoriesInsight?
    var fetchingTagsAndCategories = false

    // Insights details

    var allDotComFollowers: [StatsItem]?
    var fetchingAllDotComFollowers = false

    var allEmailFollowers: [StatsItem]?
    var fetchingAllEmailFollowers = false
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
        case .receivedAllDotComFollowers(let allDotComFollowers):
            receivedAllDotComFollowers(allDotComFollowers)
        case .receivedAllEmailFollowers(let allEmailFollowers):
            receivedAllEmailFollowers(allEmailFollowers)
        case .refreshFollowers:
            refreshFollowers()
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

        guard !activeQueries.isEmpty else {
            return
        }

        activeQueries.forEach { query in
            switch query {
            case .insights:
                if shouldFetchOverview() {
                    fetchInsights()
                }
            case .allFollowers:
                if shouldFetchFollowers() {
                    fetchAllFollowers()
                }
            }
        }
    }

    // MARK: - Insights Overview

    func fetchInsights() {

        setAllAsFetchingOverview()

        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else {
            return
        }

        let api = apiService(for: siteID)

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

        api.getInsight { (streak: StatsPostingStreakInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching tags and categories insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedPostingActivity(streak))
        }
    }

    func apiService(`for` site: Int) -> StatsServiceRemoteV2 {
        let api = WordPressComRestApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())

        return StatsServiceRemoteV2(wordPressComRestApi: api, siteID: site, siteTimezone: SiteStatsInformation.sharedInstance.siteTimeZone!)
    }

    func refreshInsights() {
        guard shouldFetchOverview() else {
            DDLogInfo("Stats Insights Overview refresh triggered while one was in progress.")
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

    func receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?) {
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

    func setAllAsFetchingOverview() {
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

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    // MARK: - Insights Details

    func fetchAllFollowers() {
        state.fetchingAllDotComFollowers = true
        state.fetchingAllEmailFollowers = true

        SiteStatsInformation.statsService()?.retrieveFollowers(of: .dotCom, withCompletionHandler: { (dotComFollowers, error) in
            if error != nil {
                DDLogInfo("Error fetching dotCom Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllDotComFollowers(dotComFollowers))
        })

        SiteStatsInformation.statsService()?.retrieveFollowers(of: .email, withCompletionHandler: { (emailFollowers, error) in
            if error != nil {
                DDLogInfo("Error fetching email Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllEmailFollowers(emailFollowers))
        })
    }

    func receivedAllDotComFollowers(_ allDotComFollowers: StatsGroup?) {
        transaction { state in
            state.allDotComFollowers = allDotComFollowers?.items as? [StatsItem]
            state.fetchingAllDotComFollowers = false
        }
    }

    func receivedAllEmailFollowers(_ allEmailFollowers: StatsGroup?) {
        transaction { state in
            state.allEmailFollowers = allEmailFollowers?.items as? [StatsItem]
            state.fetchingAllEmailFollowers = false
        }
    }

    func refreshFollowers() {
        guard shouldFetchFollowers() else {
            DDLogInfo("Stats Insights Followers refresh triggered while one was in progress.")
            return
        }

        fetchAllFollowers()
    }

    func shouldFetchFollowers() -> Bool {
        return !isFetchingFollowers
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

    func getPostingActivity() -> StatsPostingStreakInsight? {
        return state.postingActivity
    }
    /// Summarizes the daily posting count for the month in the given date.
    /// Returns an array containing every day of the month and associated post count.
    ///
    func getMonthlyPostingActivityFor(date: Date) -> [PostingStreakEvent] {

        guard
            let postingEvents = state.postingActivity?.postingEvents,
            postingEvents.count > 0
            else {
                return []
        }

        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.month, .year], from: date)

        guard
            let month = components.month,
            let year = components.year
            else {
                return []
        }

        // This gives a range of how many days there are in a given month...
        let rangeOfMonth = calendar.range(of: .day, in: .month, for: date) ?? 0..<0

        let mappedMonth = rangeOfMonth
            // then we create a `Date` representing each of those days
            .compactMap {
                return calendar.date(from: DateComponents(year: year, month: month, day: $0))
            }
            // and pick out a relevant `PostingStreakEvent` from data we have or return
            // an empty one.
            .map { (date: Date) -> PostingStreakEvent in
                if let postingEvent = postingEvents.first(where: { event in return event.date == date }) {
                    return postingEvent
                }
                return PostingStreakEvent(date: date, postCount: 0)
        }

        return mappedMonth

    }

    func getYearlyPostingActivityFrom(date: Date) -> [[PostingStreakEvent]] {
        // We operate on a "reversed" range since we want least-recent months first.
        return (0...11).reversed().compactMap {
            guard
                let monthDate = Calendar.current.date(byAdding: .month, value: -$0, to: date)
                else {
                    return nil
            }

            return getMonthlyPostingActivityFor(date: monthDate)
        }
    }

    func getAllDotComFollowers() -> [StatsItem]? {
        return state.allDotComFollowers
    }

    func getAllEmailFollowers() -> [StatsItem]? {
        return state.allEmailFollowers
    }

    var isFetchingOverview: Bool {
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

    var isFetchingFollowers: Bool {
        return
            state.fetchingAllDotComFollowers ||
            state.fetchingAllEmailFollowers
    }

}
