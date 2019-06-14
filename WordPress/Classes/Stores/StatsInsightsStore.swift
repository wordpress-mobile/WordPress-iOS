import Foundation
import WordPressKit
import WordPressFlux

enum InsightAction: Action {

    // Insights overview
    case receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?, _ error: Error?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?, _ error: Error?)
    case receivedAnnualAndMostPopularTimeStats(_ annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?, _ error: Error?)
    case receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?, _ error: Error?)
    case receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?, _ error: Error?)
    case receivedPublicize(_ publicizeStats: StatsPublicizeInsight?, _ error: Error?)
    case receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?)
    case receivedTodaysStats(_ todaysStats: StatsTodayInsight?, _ error: Error?)
    case receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?, _ error: Error?)
    case receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?)
    case refreshInsights

    // Insights details
    case receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?, _ error: Error?)
    case receivedAllEmailFollowers(_ allDotComFollowers: StatsEmailFollowersInsight?, _ error: Error?)
    case refreshFollowers

    case receivedAllCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?)
    case refreshComments

    case receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?)
    case refreshTagsAndCategories
}

enum InsightQuery {
    case insights
    case allFollowers
    case allComments
    case allTagsAndCategories
}

struct InsightStoreState {

    // Insights overview

    var lastPostInsight: StatsLastPostInsight?
    var fetchingLastPostInsight = false
    var fetchingLastPostInsightHasFailed = false

    var allTimeStats: StatsAllTimesInsight?
    var fetchingAllTimeStats = false
    var fetchingAllTimeStatsHasFailed = false

    var annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?
    var fetchingAnnualAndMostPopularTime = false
    var fetchingAnnualAndMostPopularTimeHasFailed = false

    var dotComFollowers: StatsDotComFollowersInsight?
    var fetchingDotComFollowers = false
    var fetchingDotComFollowersHasFailed = false

    var emailFollowers: StatsEmailFollowersInsight?
    var fetchingEmailFollowers = false
    var fetchingEmailFollowersHasFailed = false

    var publicizeFollowers: StatsPublicizeInsight?
    var fetchingPublicize = false
    var fetchingPublicizeHasFailed = false

    var topCommentsInsight: StatsCommentsInsight?
    var fetchingCommentsInsight = false
    var fetchingCommentsInsightHasFailed = false

    var todaysStats: StatsTodayInsight?
    var fetchingTodaysStats = false
    var fetchingTodaysStatsHasFailed = false

    var postingActivity: StatsPostingStreakInsight?
    var fetchingPostingActivity = false
    var fetchingPostingActivityHasFailed = false

    var topTagsAndCategories: StatsTagsAndCategoriesInsight?
    var fetchingTagsAndCategories = false
    var fetchingTagsAndCategoriesHasFailed = false

    // Insights details

    var allDotComFollowers: StatsDotComFollowersInsight?
    var fetchingAllDotComFollowers = false
    var fetchingAllDotComFollowersHasFailed = false

    var allEmailFollowers: StatsEmailFollowersInsight?
    var fetchingAllEmailFollowers = false
    var fetchingAllEmailFollowersHasFailed = false

    var allCommentsInsight: StatsCommentsInsight?
    var fetchingAllCommentsInsight = false
    var fetchingAllCommentsInsightHasFailed = false

    var allTagsAndCategories: StatsTagsAndCategoriesInsight?
    var fetchingAllTagsAndCategories = false
    var fetchingAllTagsAndCategoriesHasFailed = false
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
        case .receivedLastPostInsight(let lastPostInsight, let error):
            receivedLastPostInsight(lastPostInsight, error)
        case .receivedAllTimeStats(let allTimeStats, let error):
            receivedAllTimeStats(allTimeStats, error)
        case .receivedAnnualAndMostPopularTimeStats(let mostPopularStats, let error):
            receivedAnnualAndMostPopularTimeStats(mostPopularStats, error)
        case .receivedDotComFollowers(let followerStats, let error):
            receivedDotComFollowers(followerStats, error)
        case .receivedEmailFollowers(let followerStats, let error):
            receivedEmailFollowers(followerStats, error)
        case .receivedCommentsInsight(let commentsInsight, let error):
            receivedCommentsInsight(commentsInsight, error)
        case .receivedPublicize(let items, let error):
            receivedPublicizeFollowers(items, error)
        case .receivedTodaysStats(let todaysStats, let error):
            receivedTodaysStats(todaysStats, error)
        case .receivedPostingActivity(let postingActivity, let error):
            receivedPostingActivity(postingActivity, error)
        case .receivedTagsAndCategories(let tagsAndCategories, let error):
            receivedTagsAndCategories(tagsAndCategories, error)
        case .refreshInsights:
            refreshInsights()
        case .receivedAllDotComFollowers(let allDotComFollowers, let error):
            receivedAllDotComFollowers(allDotComFollowers, error)
        case .receivedAllEmailFollowers(let allEmailFollowers, let error):
            receivedAllEmailFollowers(allEmailFollowers, error)
        case .refreshFollowers:
            refreshFollowers()
        case .receivedAllCommentsInsight(let allComments, let error):
            receivedAllCommentsInsight(allComments, error)
        case .refreshComments:
            refreshComments()
        case .receivedAllTagsAndCategories(let allTagsAndCategories, let error):
            receivedAllTagsAndCategories(allTagsAndCategories, error)
        case .refreshTagsAndCategories:
            refreshTagsAndCategories()
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    func persistToCoreData() {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = BlogService.withMainContext().blog(byBlogId: siteID) else {
                return
        }

        _ = state.lastPostInsight.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.allTimeStats.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.annualAndMostPopularTime.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.dotComFollowers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.emailFollowers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.publicizeFollowers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topCommentsInsight.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.todaysStats.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.postingActivity.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topTagsAndCategories.flatMap { StatsRecord.record(from: $0, for: blog) }

        try? ContextManager.shared.mainContext.save()
    }

}

// MARK: - Private Methods

private extension StatsInsightsStore {

    func processQueries() {

        guard !activeQueries.isEmpty else {
            // This being empty means a VC just unregistered from observing data.
            // Let's persist what we have an clear the in-memory store.
            persistToCoreData()
            state = InsightStoreState()
            return
        }

        activeQueries.forEach { query in
            switch query {
            case .insights:
                loadFromCache()
            case .allFollowers:
                if shouldFetchFollowers() {
                    fetchAllFollowers()
                }
            case .allComments:
                if shouldFetchComments() {
                    fetchAllComments()
                }
            case .allTagsAndCategories:
                if shouldFetchTagsAndCategories() {
                    fetchAllTagsAndCategories()
                }
            }
        }
    }

    // MARK: - Insights Overview

    func fetchInsights() {

        loadFromCache()

        guard let api = statsRemote() else {
            return
        }

        setAllAsFetchingOverview()

        api.getInsight { (lastPost: StatsLastPostInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching last posts insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedLastPostInsight(lastPost, error))
        }

        api.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all time insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTimeStats(allTimesStats, error))
        }

        api.getInsight { (wpComFollowers: StatsDotComFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching WP.com followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(wpComFollowers, error))
        }

        api.getInsight { (emailFollowers: StatsEmailFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching email followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(emailFollowers, error))
        }

        api.getInsight { (publicizeInsight: StatsPublicizeInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching publicize insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedPublicize(publicizeInsight, error))
        }

        api.getInsight { (annualAndTime: StatsAnnualAndMostPopularTimeInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching most popular time: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAnnualAndMostPopularTimeStats(annualAndTime, error))
        }

        api.getInsight { (todayInsight: StatsTodayInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching today's insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedTodaysStats(todayInsight, error))
        }

        api.getInsight { (commentsInsights: StatsCommentsInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching comment insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedCommentsInsight(commentsInsights, error))
        }

        api.getInsight { (tagsAndCategoriesInsight: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching tags and categories insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedTagsAndCategories(tagsAndCategoriesInsight, error))
        }

        api.getInsight(limit: 5000) { (streak: StatsPostingStreakInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching posting activity insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedPostingActivity(streak, error))
        }
    }

    func loadFromCache() {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = BlogService.withMainContext().blog(byBlogId: siteID) else {
                return
        }

        transaction { state in
            state.lastPostInsight = StatsRecord.insight(for: blog, type: .lastPostInsight).flatMap { StatsLastPostInsight(statsRecordValues: $0.recordValues) }
            state.allTimeStats = StatsRecord.insight(for: blog, type: .allTimeStatsInsight).flatMap { StatsAllTimesInsight(statsRecordValues: $0.recordValues) }
            state.annualAndMostPopularTime = StatsRecord.insight(for: blog, type: .annualAndMostPopularTimes).flatMap { StatsAnnualAndMostPopularTimeInsight(statsRecordValues: $0.recordValues) }
            state.publicizeFollowers = StatsRecord.insight(for: blog, type: .publicizeConnection).flatMap { StatsPublicizeInsight(statsRecordValues: $0.recordValues) }
            state.todaysStats = StatsRecord.insight(for: blog, type: .today).flatMap { StatsTodayInsight(statsRecordValues: $0.recordValues) }
            state.postingActivity = StatsRecord.insight(for: blog, type: .streakInsight).flatMap { StatsPostingStreakInsight(statsRecordValues: $0.recordValues) }
            state.topTagsAndCategories = StatsRecord.insight(for: blog, type: .tagsAndCategories).flatMap { StatsTagsAndCategoriesInsight(statsRecordValues: $0.recordValues) }
            state.topCommentsInsight = StatsRecord.insight(for: blog, type: .commentInsight).flatMap { StatsCommentsInsight(statsRecordValues: $0.recordValues) }

            let followersInsight = StatsRecord.insight(for: blog, type: .followers)

            state.dotComFollowers = followersInsight.flatMap { StatsDotComFollowersInsight(statsRecordValues: $0.recordValues) }
            state.emailFollowers = followersInsight.flatMap { StatsEmailFollowersInsight(statsRecordValues: $0.recordValues) }
        }
    }

    func statsRemote() -> StatsServiceRemoteV2? {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
            let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone
            else {
                return nil
        }

        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: timeZone)
    }

    func refreshInsights() {
        guard shouldFetchOverview() else {
            DDLogInfo("Stats Insights Overview refresh triggered while one was in progress.")
            return
        }

        fetchInsights()
    }

    func receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?, _ error: Error?) {
        transaction { state in
            if lastPostInsight != nil {
                state.lastPostInsight = lastPostInsight
            }
            state.fetchingLastPostInsight = false
            state.fetchingLastPostInsightHasFailed = error != nil
        }
    }

    func receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?, _ error: Error?) {
        transaction { state in
            if allTimeStats != nil {
                state.allTimeStats = allTimeStats
            }
            state.fetchingAllTimeStats = false
            state.fetchingAllTimeStatsHasFailed = error != nil
        }
    }

    func receivedAnnualAndMostPopularTimeStats(_ mostPopularStats: StatsAnnualAndMostPopularTimeInsight?, _ error: Error?) {
        transaction { state in
            if mostPopularStats != nil {
                state.annualAndMostPopularTime = mostPopularStats
            }
            state.fetchingAnnualAndMostPopularTime = false
            state.fetchingAnnualAndMostPopularTimeHasFailed = error != nil
        }
    }

    func receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.dotComFollowers = followerStats
            }
            state.fetchingDotComFollowers = false
            state.fetchingDotComFollowersHasFailed = error != nil
        }
    }

    func receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.emailFollowers = followerStats
            }
            state.fetchingEmailFollowers = false
            state.fetchingEmailFollowersHasFailed = error != nil
        }
    }

    func receivedPublicizeFollowers(_ followerStats: StatsPublicizeInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.publicizeFollowers = followerStats
            }
            state.fetchingPublicize = false
            state.fetchingPublicizeHasFailed = error != nil
        }
    }

    func receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?) {
        transaction { state in
            if commentsInsight != nil {
                state.topCommentsInsight = commentsInsight
            }
            state.fetchingCommentsInsight = false
            state.fetchingCommentsInsightHasFailed = error != nil
        }
    }

    func receivedTodaysStats(_ todaysStats: StatsTodayInsight?, _ error: Error?) {
        transaction { state in
            if todaysStats != nil {
                state.todaysStats = todaysStats
            }
            state.fetchingTodaysStats = false
            state.fetchingTodaysStatsHasFailed = error != nil
        }
    }

    func receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?, _ error: Error?) {
        transaction { state in
            if postingActivity != nil {
                state.postingActivity = postingActivity
            }
            state.fetchingPostingActivity = false
            state.fetchingPostingActivityHasFailed = error != nil
        }
    }

    func receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?) {
        transaction { state in
            if tagsAndCategories != nil {
                state.topTagsAndCategories = tagsAndCategories
            }
            state.fetchingTagsAndCategories = false
            state.fetchingTagsAndCategoriesHasFailed = error != nil
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
        guard let api = statsRemote() else {
            return
        }

        state.fetchingAllDotComFollowers = true
        state.fetchingAllEmailFollowers = true

        // The followers API returns a maximum of 100 results.
        // Using a limit of 0 returns the default 20 results.
        // So use limit 100 to get max results.

        api.getInsight(limit: 100) { (dotComFollowers: StatsDotComFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching dotCom Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllDotComFollowers(dotComFollowers, error))
        }

          api.getInsight(limit: 100) { (emailFollowers: StatsEmailFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching email Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllEmailFollowers(emailFollowers, error))
        }
    }

    func fetchAllComments() {
        guard let api = statsRemote() else {
            return
        }

        state.fetchingAllCommentsInsight = true

        // The API doesn't work when we specify `0` here, like most of the other endpoints do, unfortunately...
        // 1000 was chosen as an arbitrarily large number that should be "big enough" for all of our users.

        api.getInsight(limit: 1000) {(allComments: StatsCommentsInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all comments: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllCommentsInsight(allComments, error))
        }
    }

    func fetchAllTagsAndCategories() {
        guard let api = statsRemote() else {
            return
        }

        state.fetchingAllTagsAndCategories = true

        // See the comment about the limit in the method above.
        api.getInsight(limit: 1000) { (allTagsAndCategories: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all tags and categories: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTagsAndCategories(allTagsAndCategories, error))
        }
    }

    func receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?, _ error: Error?) {
        transaction { state in
            if allDotComFollowers != nil {
                state.allDotComFollowers = allDotComFollowers
            }
            state.fetchingAllDotComFollowers = false
            state.fetchingAllDotComFollowersHasFailed = error != nil
        }
    }

    func receivedAllEmailFollowers(_ allEmailFollowers: StatsEmailFollowersInsight?, _ error: Error?) {
        transaction { state in
            if allEmailFollowers != nil {
                state.allEmailFollowers = allEmailFollowers
            }
            state.fetchingAllEmailFollowers = false
            state.fetchingAllEmailFollowersHasFailed = error != nil
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

    func receivedAllCommentsInsight(_ allCommentsInsight: StatsCommentsInsight?, _ error: Error?) {
        transaction { state in
            if allCommentsInsight != nil {
                state.allCommentsInsight = allCommentsInsight
            }
            state.fetchingAllCommentsInsight = false
            state.fetchingAllCommentsInsightHasFailed = error != nil
        }
    }

    func refreshComments() {
        guard shouldFetchComments() else {
            DDLogInfo("Stats Insights Comments refresh triggered while one was in progress.")
            return
        }

        fetchAllComments()
    }

    func shouldFetchComments() -> Bool {
        return !isFetchingComments
    }

    func receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?) {
        transaction { state in
            if allTagsAndCategories != nil {
                state.allTagsAndCategories = allTagsAndCategories
            }
            state.fetchingAllTagsAndCategories = false
            state.fetchingAllTagsAndCategoriesHasFailed = error != nil
        }
    }

    func refreshTagsAndCategories() {
        guard shouldFetchTagsAndCategories() else {
            DDLogInfo("Stats Insights Tags And Categories refresh triggered while one was in progress.")
            return
        }

        fetchAllTagsAndCategories()
    }

    func shouldFetchTagsAndCategories() -> Bool {
        return !isFetchingTagsAndCategories
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

        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.month, .year], from: date)

        guard
            let month = components.month,
            let year = components.year
            else {
                return []
        }

        let postingEvents = state.postingActivity?.postingEvents ?? []

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

    func getAllDotComFollowers() -> StatsDotComFollowersInsight? {
        return state.allDotComFollowers
    }

    func getAllEmailFollowers() -> StatsEmailFollowersInsight? {
        return state.allEmailFollowers
    }

    func getAllCommentsInsight() -> StatsCommentsInsight? {
        return state.allCommentsInsight
    }

    func getAllTagsAndCategories() -> StatsTagsAndCategoriesInsight? {
        return state.allTagsAndCategories
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

    var isFetchingComments: Bool {
        return state.fetchingAllCommentsInsight
    }

    var isFetchingTagsAndCategories: Bool {
        return state.fetchingAllTagsAndCategories
    }

    var fetchingOverviewHasFailed: Bool {
        return
            state.fetchingLastPostInsightHasFailed &&
            state.fetchingAllTimeStatsHasFailed &&
            state.fetchingAnnualAndMostPopularTimeHasFailed &&
            state.fetchingDotComFollowersHasFailed &&
            state.fetchingEmailFollowersHasFailed &&
            state.fetchingPublicizeHasFailed &&
            state.fetchingTodaysStatsHasFailed &&
            state.fetchingPostingActivityHasFailed &&
            state.fetchingCommentsInsightHasFailed &&
            state.fetchingTagsAndCategoriesHasFailed
    }

    func fetchingFailed(for query: InsightQuery) -> Bool {
        switch query {
        case .insights:
            return fetchingOverviewHasFailed
        case .allFollowers:
            return state.fetchingAllDotComFollowersHasFailed &&
                state.fetchingAllEmailFollowersHasFailed
        case .allComments:
            return state.fetchingAllCommentsInsightHasFailed
        case .allTagsAndCategories:
            return state.fetchingAllTagsAndCategoriesHasFailed
        }
    }

    var containsCachedData: Bool {
        if state.lastPostInsight != nil ||
            state.allTimeStats != nil ||
            state.annualAndMostPopularTime != nil ||
            state.publicizeFollowers != nil ||
            state.todaysStats != nil ||
            state.postingActivity != nil ||
            state.topTagsAndCategories != nil ||
            state.topCommentsInsight != nil ||
            state.dotComFollowers != nil ||
            state.emailFollowers != nil {
                return true
        }

        return false
    }
}
