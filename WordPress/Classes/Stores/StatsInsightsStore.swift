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
    case receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?)
    case receivedAllEmailFollowers(_ allDotComFollowers: StatsEmailFollowersInsight?)
    case refreshFollowers()

    case receivedAllAuthorsComments()
    case receivedAllPostsComments()
    case refreshComments()

    case receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?)
    case refreshTagsAndCategories()
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

    var allDotComFollowers: StatsDotComFollowersInsight?
    var fetchingAllDotComFollowers = false

    var allEmailFollowers: StatsEmailFollowersInsight?
    var fetchingAllEmailFollowers = false

    var allAuthorsComments: StatsCommentsInsight?
    var fetchingAllAuthorsComments = false

    var allPostsComments: StatsCommentsInsight?
    var fetchingAllPostsComments = false

    var allTagsAndCategories: StatsTagsAndCategoriesInsight?
    var fetchingAllTagsAndCategories = false
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
        case .receivedAllAuthorsComments:
            receivedAllAuthorsComments()
        case .receivedAllPostsComments:
            receivedAllPostsComments()
        case .refreshComments:
            refreshComments()
        case .receivedAllTagsAndCategories(let allTagsAndCategories):
            receivedAllTagsAndCategories(allTagsAndCategories)
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

        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else {
            return
        }

        setAllAsFetchingOverview()
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
            if lastPostInsight != nil {
                state.lastPostInsight = lastPostInsight
            }
            state.fetchingLastPostInsight = false
        }
    }

    func receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?) {
        transaction { state in
            if allTimeStats != nil {
                state.allTimeStats = allTimeStats
            }
            state.fetchingAllTimeStats = false
        }
    }

    func receivedAnnualAndMostPopularTimeStats(_ mostPopularStats: StatsAnnualAndMostPopularTimeInsight?) {
        transaction { state in
            if mostPopularStats != nil {
                state.annualAndMostPopularTime = mostPopularStats
            }
            state.fetchingAnnualAndMostPopularTime = false
        }
    }

    func receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?) {
        transaction { state in
            if followerStats != nil {
                state.dotComFollowers = followerStats
            }
            state.fetchingDotComFollowers = false
        }
    }

    func receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?) {
        transaction { state in
            if followerStats != nil {
                state.emailFollowers = followerStats
            }
            state.fetchingEmailFollowers = false
        }
    }

    func receivedPublicizeFollowers(_ followerStats: StatsPublicizeInsight?) {
        transaction { state in
            if followerStats != nil {
                state.publicizeFollowers = followerStats
            }
            state.fetchingPublicize = false
        }
    }

    func receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?) {
        transaction { state in
            if commentsInsight != nil {
                state.topCommentsInsight = commentsInsight
            }
            state.fetchingCommentsInsight = false
        }
    }

    func receivedTodaysStats(_ todaysStats: StatsTodayInsight?) {
        transaction { state in
            if todaysStats != nil {
                state.todaysStats = todaysStats
            }
            state.fetchingTodaysStats = false
        }
    }

    func receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?) {
        transaction { state in
            if postingActivity != nil {
                state.postingActivity = postingActivity
            }
            state.fetchingPostingActivity = false
        }
    }

    func receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?) {
        transaction { state in
            if tagsAndCategories != nil {
                state.topTagsAndCategories = tagsAndCategories
            }
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
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else {
            return
        }

        state.fetchingAllDotComFollowers = true
        state.fetchingAllEmailFollowers = true

        let api = apiService(for: siteID)

        api.getInsight(limit: 0) { (dotComFollowers: StatsDotComFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching dotCom Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllDotComFollowers(dotComFollowers))
        }

          api.getInsight(limit: 0) { (emailFollowers: StatsEmailFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching email Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllEmailFollowers(emailFollowers))
        }
    }

    func fetchAllComments() {
        state.fetchingAllAuthorsComments = true
        state.fetchingAllPostsComments = true

        // TODO: replace with api call when fetch all author and post comments is supported.
        actionDispatcher.dispatch(InsightAction.receivedAllAuthorsComments())
        actionDispatcher.dispatch(InsightAction.receivedAllPostsComments())
    }

    func fetchAllTagsAndCategories() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else {
            return
        }

        state.fetchingAllTagsAndCategories = true

        let api = apiService(for: siteID)

        // The API doesn't work when we specify `0` here, like most of the other endpoints do, unfortunately...
        // 100 was chosen as an arbitraily large number that should be "big enough" for all of our users
        // but I'm open to increasing it.
        api.getInsight(limit: 100) { (allTagsAndCategories: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all tags and categories: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTagsAndCategories(allTagsAndCategories))
        }
    }

    func receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?) {
        transaction { state in
            if allDotComFollowers != nil {
                state.allDotComFollowers = allDotComFollowers
            }
            state.fetchingAllDotComFollowers = false
        }
    }

    func receivedAllEmailFollowers(_ allEmailFollowers: StatsEmailFollowersInsight?) {
        transaction { state in
            if allEmailFollowers != nil {
                state.allEmailFollowers = allEmailFollowers
            }
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

    func receivedAllAuthorsComments() {
        transaction { state in
            // TODO: replace with real allAuthorsComments when API supports it.
            state.allAuthorsComments = state.topCommentsInsight
            state.fetchingAllAuthorsComments = false
        }
    }

    func receivedAllPostsComments() {
        transaction { state in
            // TODO: replace with real allPostsComments when API supports it.
            state.allPostsComments = state.topCommentsInsight
            state.fetchingAllPostsComments = false
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

    func receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?) {
        transaction { state in
            if allTagsAndCategories != nil {
                state.allTagsAndCategories = allTagsAndCategories
            }
            state.fetchingAllTagsAndCategories = false
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

    func getAllDotComFollowers() -> StatsDotComFollowersInsight? {
        return state.allDotComFollowers
    }

    func getAllEmailFollowers() -> StatsEmailFollowersInsight? {
        return state.allEmailFollowers
    }

    func getAllAuthorsComments() -> StatsCommentsInsight? {
        return state.allAuthorsComments
    }

    func getAllPostsComments() -> StatsCommentsInsight? {
        return state.allPostsComments
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
        return
            state.fetchingAllAuthorsComments ||
            state.fetchingAllPostsComments
    }

    var isFetchingTagsAndCategories: Bool {
        return state.fetchingAllTagsAndCategories
    }

}
