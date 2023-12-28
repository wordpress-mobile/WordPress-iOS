import Foundation
import WordPressKit
import WordPressFlux
import WidgetKit

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
    case refreshInsights(forceRefresh: Bool)

    // Insights details
    case receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?, _ error: Error?)
    case receivedAllEmailFollowers(_ allDotComFollowers: StatsEmailFollowersInsight?, _ error: Error?)
    case refreshFollowers

    case receivedAllCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?)
    case refreshComments

    case receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?)
    case refreshTagsAndCategories

    case receivedAllAnnual(_ allAnnual: StatsAllAnnualInsight?, _ error: Error?)
    case refreshAnnual
}

enum InsightQuery {
    case insights
    case allFollowers
    case allComments
    case allTagsAndCategories
    case allAnnual
}

struct InsightStoreState {

    // Insights overview

    // LPS

    var lastPostInsight: StatsLastPostInsight?
    var postStats: StatsPostDetails?
    var lastPostSummaryStatus: StoreFetchingStatus = .idle

    // Other Blocks

    var allTimeStats: StatsAllTimesInsight? {
        didSet {
            guard let stats = allTimeStats else {
                return
            }
            let widgetData = AllTimeWidgetStats(views: stats.viewsCount,
                                                visitors: stats.visitorsCount,
                                                posts: stats.postsCount,
                                                bestViews: stats.bestViewsPerDayCount)
            StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetAllTimeData.self, stats: widgetData)
        }
    }
    var allTimeStatus: StoreFetchingStatus = .idle

    var annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?
    var annualAndMostPopularTimeStatus: StoreFetchingStatus = .idle

    var dotComFollowers: StatsDotComFollowersInsight?
    var dotComFollowersStatus: StoreFetchingStatus = .idle

    var emailFollowers: StatsEmailFollowersInsight?
    var emailFollowersStatus: StoreFetchingStatus = .idle

    var publicizeFollowers: StatsPublicizeInsight?
    var publicizeFollowersStatus: StoreFetchingStatus = .idle

    var topCommentsInsight: StatsCommentsInsight?
    var commentsInsightStatus: StoreFetchingStatus = .idle

    var todaysStats: StatsTodayInsight? {
        didSet {
            guard let stats = todaysStats else {
                return
            }
            let widgetData = TodayWidgetStats(views: stats.viewsCount,
                                              visitors: stats.visitorsCount,
                                              likes: stats.likesCount,
                                              comments: stats.commentsCount)

            StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetTodayData.self, stats: widgetData)
        }
    }
    var todaysStatsStatus: StoreFetchingStatus = .idle

    var postingActivity: StatsPostingStreakInsight?
    var postingActivityStatus: StoreFetchingStatus = .idle

    var topTagsAndCategories: StatsTagsAndCategoriesInsight?
    var tagsAndCategoriesStatus: StoreFetchingStatus = .idle

    // Insights details

    var allDotComFollowers: StatsDotComFollowersInsight?
    var allDotComFollowersStatus: StoreFetchingStatus = .idle

    var allEmailFollowers: StatsEmailFollowersInsight?
    var allEmailFollowersStatus: StoreFetchingStatus = .idle

    var allCommentsInsight: StatsCommentsInsight?
    var allCommentsInsightStatus: StoreFetchingStatus = .idle

    var allTagsAndCategories: StatsTagsAndCategoriesInsight?
    var allTagsAndCategoriesStatus: StoreFetchingStatus = .idle

    var allAnnual: StatsAllAnnualInsight?
    var allAnnualStatus: StoreFetchingStatus = .idle
}

class StatsInsightsStore: QueryStore<InsightStoreState, InsightQuery> {

    private let cache: StatsInsightsCache = .shared

    init() {
        super.init(initialState: InsightStoreState())
    }

    /// A set containing all the data types associated with the currently visible Insights cards
    /// which defines the number and type of api calls we need to perform.
    var currentDataTypes: Set<InsightDataType> {
        Set(SiteStatsInformation.sharedInstance
                .getCurrentSiteInsights()  // The current visible cards
                .reduce(into: [InsightDataType]()) {
            $0.append(contentsOf: $1.insightsDataForSection)
        }) // And the respective associated data
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
        case .refreshInsights(let forceRefresh):
            refreshInsights(forceRefresh: forceRefresh)
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
        case .receivedAllAnnual(let allAnnual, let error):
            receivedAllAnnual(allAnnual, error)
        case .refreshAnnual:
            refreshAnnual()
        }

        if !isFetchingOverview {
            DDLogInfo("Stats: Insights Overview refreshing operations finished.")
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    func saveDataInCache() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func setValue<T: StatsInsightData>(_ value: T, _ record: StatsInsightsCache.Record) {
            cache.setValue(value, record: record, siteID: siteID)
        }
        state.lastPostInsight.map { setValue($0, .lastPostInsight) }
        state.allTimeStats.map { setValue($0, .allTimeStats) }
        state.annualAndMostPopularTime.map { setValue($0, .annualAndMostPopularTime) }
        state.dotComFollowers.map { setValue($0, .dotComFollowers) }
        state.emailFollowers.map { setValue($0, .emailFollowers) }
        state.publicizeFollowers.map { setValue($0, .publicizeFollowers) }
        state.topCommentsInsight.map { setValue($0, .topCommentsInsight) }
        state.todaysStats.map { setValue($0, .todaysStats) }
        state.postingActivity.map { setValue($0, .postingActivity) }
        state.topTagsAndCategories.map { setValue($0, .topTagsAndCategories) }

        cache.setLastRefreshDate(Date(), forSiteID: siteID)
    }
}

// MARK: - Private Methods

private extension StatsInsightsStore {

    func processQueries() {

        guard !activeQueries.isEmpty else {
            // This being empty means a VC just unregistered from observing data.
            // Let's persist what we have an clear the in-memory store.
            saveDataInCache()
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
            case .allAnnual:
                if shouldFetchAnnual() {
                    fetchAllAnnual()
                }
            }
        }
    }

    // MARK: - Insights Overview

    func fetchInsights() {
        updateFetchingStatusForVisibleCards(.loading)
        fetchInsightsCards()
    }

    func fetchInsightsCards() {
        guard let api = statsRemote() else {
            setAllFetchingStatus(.idle)
            return
        }

        currentDataTypes.forEach {
            fetchInsightsForCard(type: $0, api: api)
        }
    }

    func fetchInsightsForCard(type: InsightDataType, api: StatsServiceRemoteV2) {
        switch type {
        case .latestPost:
            api.getInsight { (lastPost: StatsLastPostInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching last posts insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedLastPostInsight(lastPost, error))
                DDLogInfo("Stats: Insights - successfully fetched latest post summary")
            }
        case .allTime:
            api.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching all time insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedAllTimeStats(allTimesStats, error))
                DDLogInfo("Stats: Insights - successfully fetched all time")
            }

        case .annualAndMostPopular:
            api.getInsight { (annualAndTime: StatsAnnualAndMostPopularTimeInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching annual/most popular time: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedAnnualAndMostPopularTimeStats(annualAndTime, error))
                DDLogInfo("Stats: Insights - successfully fetched annual and most popular")
            }
        case .tagsAndCategories:
            api.getInsight { (tagsAndCategoriesInsight: StatsTagsAndCategoriesInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching tags and categories insight: \(error.localizedDescription)")
                }

                self.actionDispatcher.dispatch(InsightAction.receivedTagsAndCategories(tagsAndCategoriesInsight, error))
                DDLogInfo("Stats: Insights - successfully fetched tags and categories")
            }

        case .comments:
            api.getInsight { (commentsInsights: StatsCommentsInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching comment insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedCommentsInsight(commentsInsights, error))
                DDLogInfo("Stats: Insights - successfully fetched comments")
            }
        case .followers:
            api.getInsight { (wpComFollowers: StatsDotComFollowersInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching WP.com followers: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(wpComFollowers, error))
                DDLogInfo("Stats: Insights - successfully fetched wp.com followers")
            }

            api.getInsight { (emailFollowers: StatsEmailFollowersInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching email followers: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(emailFollowers, error))
                DDLogInfo("Stats: Insights - successfully fetched email followers")
            }
        case .today:
            api.getInsight { (todayInsight: StatsTodayInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching today's insight: \(error.localizedDescription)")
                }

                self.actionDispatcher.dispatch(InsightAction.receivedTodaysStats(todayInsight, error))
                DDLogInfo("Stats: Insights - successfully fetched today")
            }
        case .postingActivity:
            api.getInsight(limit: 5000) { (streak: StatsPostingStreakInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching posting activity insight: \(error.localizedDescription)")
                }

                self.actionDispatcher.dispatch(InsightAction.receivedPostingActivity(streak, error))
                DDLogInfo("Stats: Insights - successfully fetched posting activity")
            }
        case .publicize:
            api.getInsight { (publicizeInsight: StatsPublicizeInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching publicize insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedPublicize(publicizeInsight, error))
                DDLogInfo("Stats: Insights - successfully fetched publicize")
            }
        }
    }

    func loadFromCache() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }
        func getValue<T: StatsInsightData>(_ record: StatsInsightsCache.Record) -> T? {
            cache.getValue(record: record, siteID: siteID)
        }

        transaction { state in
            state.lastPostInsight = getValue(.lastPostInsight)
            state.allTimeStats = getValue(.allTimeStats)
            state.annualAndMostPopularTime = getValue(.annualAndMostPopularTime)
            state.publicizeFollowers = getValue(.publicizeFollowers)
            state.todaysStats = getValue(.todaysStats)
            state.postingActivity = getValue(.postingActivity)
            state.topTagsAndCategories = getValue(.topTagsAndCategories)
            state.topCommentsInsight = getValue(.topCommentsInsight)
            state.dotComFollowers = getValue(.dotComFollowers)
            state.emailFollowers = getValue(.emailFollowers)

            state.lastPostSummaryStatus = state.lastPostInsight == nil ? .error : .success
            state.allTimeStatus = state.allTimeStats == nil ? .error : .success
            state.annualAndMostPopularTimeStatus = state.annualAndMostPopularTime != nil ? .error : .success
            state.publicizeFollowersStatus = state.publicizeFollowers == nil ? .error : .success
            state.todaysStatsStatus = state.todaysStats == nil ? .error : .success
            state.postingActivityStatus = state.postingActivity == nil ? .error : .success
            state.tagsAndCategoriesStatus = state.topTagsAndCategories == nil ? .error : .success
            state.commentsInsightStatus = state.topCommentsInsight == nil ? .error : .success
            state.dotComFollowersStatus = state.dotComFollowers == nil ? .error : .success
            state.emailFollowersStatus = state.emailFollowers == nil ? .error : .success
        }

        DDLogInfo("Insights load from cache")
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

    func refreshInsights(forceRefresh: Bool = false) {
        guard shouldFetchOverview() else {
            DDLogInfo("Stats: Insights Overview refresh triggered while one was in progress.")
            return
        }

        guard forceRefresh || cache.isExpired else {
            DDLogInfo("Stats: Insights Overview refresh requested but we still have valid cache data.")
            return
        }

        if forceRefresh {
            DDLogInfo("Stats: Forcing an Insights refresh.")
        }

        saveDataInCache()
        fetchInsights()
    }

    func fetchLastPostSummary() {
        guard let api = statsRemote() else {
            setAllFetchingStatus(.idle)
            state.lastPostSummaryStatus = .idle
            return
        }

        api.getInsight { (lastPost: StatsLastPostInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching last posts insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedLastPostInsight(lastPost, error))
            DDLogInfo("Stats: Insights - successfully fetched latest post summary.")
        }
    }

    func fetchStatsForInsightsLatestPost() {
        guard let postID = getLastPostInsight()?.postID,
            let api = statsRemote() else {
            state.lastPostSummaryStatus = .idle
            return
        }

        api.getDetails(forPostID: postID) { (postStats: StatsPostDetails?, error: Error?) in
            if let error = error {
                DDLogError("Insights: Error fetching Post Stats: \(error.localizedDescription)")
            }
            DDLogInfo("Stats: Insights - successfully fetched latest post details.")

            DispatchQueue.main.async {
                self.receivedPostStats(postStats, error)
            }
        }
    }

    func receivedPostStats(_ postStats: StatsPostDetails?, _ error: Error?) {
        transaction { state in
            if postStats != nil {
                state.postStats = postStats
            }
            state.lastPostSummaryStatus = error != nil ? .error : .success
        }
    }

    func receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?, _ error: Error?) {
        if lastPostInsight != nil {
            state.lastPostInsight = lastPostInsight
            fetchStatsForInsightsLatestPost()
            return
        }
        transaction { state in
            state.lastPostSummaryStatus = error != nil ? .error : .success
        }
    }

    func receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?, _ error: Error?) {
        transaction { state in
            if allTimeStats != nil {
                state.allTimeStats = allTimeStats
            }
            state.allTimeStatus = error != nil ? .error : .success
        }
    }

    func receivedAnnualAndMostPopularTimeStats(_ mostPopularStats: StatsAnnualAndMostPopularTimeInsight?, _ error: Error?) {
        transaction { state in
            if mostPopularStats != nil {
                state.annualAndMostPopularTime = mostPopularStats
            }
            state.annualAndMostPopularTimeStatus = error != nil ? .error : .success
        }
    }

    func receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.dotComFollowers = followerStats
            }
            state.dotComFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.emailFollowers = followerStats
            }
            state.emailFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedPublicizeFollowers(_ followerStats: StatsPublicizeInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.publicizeFollowers = followerStats
            }
            state.publicizeFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?) {
        transaction { state in
            if commentsInsight != nil {
                state.topCommentsInsight = commentsInsight
            }
            state.commentsInsightStatus = error != nil ? .error : .success
        }
    }

    func receivedTodaysStats(_ todaysStats: StatsTodayInsight?, _ error: Error?) {
        transaction { state in
            if todaysStats != nil {
                state.todaysStats = todaysStats
            }
            state.todaysStatsStatus = error != nil ? .error : .success
        }
    }

    func receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?, _ error: Error?) {
        transaction { state in
            if postingActivity != nil {
                state.postingActivity = postingActivity
            }
            state.postingActivityStatus = error != nil ? .error : .success
        }
    }

    func receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?) {
        transaction { state in
            if tagsAndCategories != nil {
                state.topTagsAndCategories = tagsAndCategories
            }
            state.tagsAndCategoriesStatus = error != nil ? .error : .success
        }
    }

    /// Updates the current fetching status on data types associated with visible cards. Other data types status will remain unchanged.
    /// - Parameter status: the new status to set
    func updateFetchingStatusForVisibleCards( _ status: StoreFetchingStatus) {
        state.lastPostSummaryStatus = currentDataTypes.contains(.latestPost) ? status : state.lastPostSummaryStatus
        state.allTimeStatus = currentDataTypes.contains(.allTime) ? status : state.allTimeStatus
        state.annualAndMostPopularTimeStatus = currentDataTypes.contains(.annualAndMostPopular) ? status : state.annualAndMostPopularTimeStatus
        state.dotComFollowersStatus = currentDataTypes.contains(.followers) ? status : state.dotComFollowersStatus
        state.emailFollowersStatus = currentDataTypes.contains(.followers) ? status : state.emailFollowersStatus
        state.todaysStatsStatus = currentDataTypes.contains(.today) ? status : state.todaysStatsStatus
        state.tagsAndCategoriesStatus = currentDataTypes.contains(.tagsAndCategories) ? status : state.tagsAndCategoriesStatus
        state.publicizeFollowersStatus = currentDataTypes.contains(.publicize) ? status : state.publicizeFollowersStatus
        state.commentsInsightStatus = currentDataTypes.contains(.comments) ? status : state.commentsInsightStatus
        state.postingActivityStatus = currentDataTypes.contains(.postingActivity) ? status : state.postingActivityStatus
    }

    func setAllFetchingStatus(_ status: StoreFetchingStatus) {
        state.lastPostSummaryStatus = status
        state.allTimeStatus = status
        state.annualAndMostPopularTimeStatus = status
        state.dotComFollowersStatus = status
        state.emailFollowersStatus = status
        state.todaysStatsStatus = status
        state.tagsAndCategoriesStatus = status
        state.publicizeFollowersStatus = status
        state.commentsInsightStatus = status
        state.postingActivityStatus = status
    }

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    // MARK: - Insights Details

    func fetchAllFollowers() {
        guard let api = statsRemote() else {
            return
        }

        state.allDotComFollowersStatus = .loading
        state.allEmailFollowersStatus = .loading

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

        state.allCommentsInsightStatus = .loading

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

        state.allTagsAndCategoriesStatus = .loading

        // See the comment about the limit in the method above.
        api.getInsight(limit: 1000) { (allTagsAndCategories: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all tags and categories: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTagsAndCategories(allTagsAndCategories, error))
        }
    }

    func fetchAllAnnual() {
        guard let api = statsRemote() else {
            return
        }

        state.allAnnualStatus = .loading

        api.getInsight { (allAnnual: StatsAllAnnualInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all annual: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllAnnual(allAnnual, error))
        }
    }

    func receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?, _ error: Error?) {
        transaction { state in
            if allDotComFollowers != nil {
                state.allDotComFollowers = allDotComFollowers
            }
            state.allDotComFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedAllEmailFollowers(_ allEmailFollowers: StatsEmailFollowersInsight?, _ error: Error?) {
        transaction { state in
            if allEmailFollowers != nil {
                state.allEmailFollowers = allEmailFollowers
            }
            state.allEmailFollowersStatus = error != nil ? .error : .success
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
        return !isFetchingAllFollowers
    }

    func receivedAllCommentsInsight(_ allCommentsInsight: StatsCommentsInsight?, _ error: Error?) {
        transaction { state in
            if allCommentsInsight != nil {
                state.allCommentsInsight = allCommentsInsight
            }
            state.allCommentsInsightStatus = error != nil ? .error : .success
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
            state.allTagsAndCategoriesStatus = error != nil ? .error : .success
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

    func receivedAllAnnual(_ allAnnual: StatsAllAnnualInsight?, _ error: Error?) {
        transaction { state in
            if allAnnual != nil {
                state.allAnnual = allAnnual
            }
            state.allAnnualStatus = error != nil ? .error : .success
        }
    }

    func refreshAnnual() {
        guard shouldFetchAnnual() else {
            DDLogInfo("Stats Insights Annual refresh triggered while one was in progress.")
            return
        }

        fetchAllAnnual()
    }

    func shouldFetchAnnual() -> Bool {
        return !isFetchingAnnual
    }
}

// MARK: - Public Accessors

extension StatsInsightsStore {

    func getLastPostInsight() -> StatsLastPostInsight? {
        return state.lastPostInsight
    }

    func getPostStats() -> StatsPostDetails? {
        return state.postStats
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

    func getTotalFollowerCount() -> Int {
        let totalDotComFollowers = getDotComFollowers()?.dotComFollowersCount ?? 0
        let totalEmailFollowers = getEmailFollowers()?.emailFollowersCount ?? 0
        let totalPublicize = getPublicizeCount()

        return totalDotComFollowers + totalEmailFollowers + totalPublicize
    }

    func getPublicize() -> StatsPublicizeInsight? {
        return state.publicizeFollowers
    }

    func getPublicizeCount() -> Int {
        var totalPublicize = 0
        if let publicize = getPublicize(),
           !publicize.publicizeServices.isEmpty {
            totalPublicize = publicize.publicizeServices.compactMap({$0.followers}).reduce(0, +)
        }

        return totalPublicize
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
    func getMonthlyPostingActivity(for date: Date) -> [PostingStreakEvent] {
        let postingEventDates = getPostingEventsDates()

        return getMonthlyPostingActivityFor(date: date, postingEventsDates: postingEventDates)
    }

    func getQuarterlyPostingActivity(from date: Date) -> [[PostingStreakEvent]] {
        let postingEventDates = getPostingEventsDates()
        var quarterlyData = [[PostingStreakEvent]]()

        if let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: date) {
            quarterlyData.append(getMonthlyPostingActivityFor(date: twoMonthsAgo, postingEventsDates: postingEventDates))
        }

        if let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: date) {
            quarterlyData.append(getMonthlyPostingActivityFor(date: oneMonthAgo, postingEventsDates: postingEventDates))
        }

        quarterlyData.append(getMonthlyPostingActivityFor(date: date, postingEventsDates: postingEventDates))

        return quarterlyData
    }

    func getYearlyPostingActivity(from date: Date) -> [[PostingStreakEvent]] {
        let postingEventsDates = getPostingEventsDates()

        // We operate on a "reversed" range since we want least-recent months first.
        return (0...11).reversed().compactMap {
            guard
                let monthDate = Calendar.current.date(byAdding: .month, value: -$0, to: date)
                else {
                    return nil
            }

            return getMonthlyPostingActivityFor(date: monthDate, postingEventsDates: postingEventsDates)
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

    func getAllAnnual() -> StatsAllAnnualInsight? {
        return state.allAnnual
    }

    var lastPostSummaryStatus: StoreFetchingStatus {
        return state.lastPostSummaryStatus
    }

    var allTimeStatus: StoreFetchingStatus {
        return state.allTimeStatus
    }

    var todaysStatsStatus: StoreFetchingStatus {
        return state.todaysStatsStatus
    }

    var tagsAndCategoriesStatus: StoreFetchingStatus {
        return state.tagsAndCategoriesStatus
    }

    var publicizeFollowersStatus: StoreFetchingStatus {
        return state.publicizeFollowersStatus
    }

    var commentsInsightStatus: StoreFetchingStatus {
        return state.commentsInsightStatus
    }

    var postingActivityStatus: StoreFetchingStatus {
        return state.postingActivityStatus
    }

    var followersTotalsStatus: StoreFetchingStatus {
        switch (state.dotComFollowersStatus, state.emailFollowersStatus) {
        case (let a, let b) where a == .loading || b == .loading:
            return .loading
        case (let a, let b) where a == .error || b == .error:
            return .error
        case (.success, .success):
            return .success
        default:
            return .idle
        }
    }

    var annualAndMostPopularTimeStatus: StoreFetchingStatus {
        return state.annualAndMostPopularTimeStatus
    }

    var isFetchingOverview: Bool {
        /*
         * Use reflection here to inspect all the members of type StoreFetchingStatus
         * with value .loading. If at least one exists then the store is still fetching the overview.
         */
        let mirror = Mirror(reflecting: state)
        return mirror.children.compactMap { $0.value as? StoreFetchingStatus }.first { $0 == .loading } != nil
    }

    var isFetchingAllFollowers: Bool {
        return state.allDotComFollowersStatus == .loading ||
                state.allEmailFollowersStatus == .loading
    }

    var allDotComFollowersStatus: StoreFetchingStatus {
        return state.allDotComFollowersStatus
    }

    var allEmailFollowersStatus: StoreFetchingStatus {
        return state.allEmailFollowersStatus
    }

    var fetchingFollowersStatus: StoreFetchingStatus {
        switch (state.allDotComFollowersStatus, state.allEmailFollowersStatus) {
        case (let a, let b) where a == .loading || b == .loading:
            return .loading
        case (.error, .error):
            return .error
        case (let a, let b) where a == .success || b == .success:
            return .success
        default:
            return .idle
        }
    }

    var allCommentsInsightStatus: StoreFetchingStatus {
        return state.allCommentsInsightStatus
    }

    var isFetchingComments: Bool {
        return allCommentsInsightStatus == .loading
    }

    var allTagsAndCategoriesStatus: StoreFetchingStatus {
        return state.allTagsAndCategoriesStatus
    }

    var isFetchingTagsAndCategories: Bool {
        return allTagsAndCategoriesStatus == .loading
    }

    var allAnnualStatus: StoreFetchingStatus {
        return state.allAnnualStatus
    }

    var isFetchingAnnual: Bool {
        return allAnnualStatus == .loading
    }

    var fetchingOverviewHasFailed: Bool {
        /*
         * Use reflection here to inspect all the members of type StoreFetchingStatus
         * with value different from .error.
         * If the result is nil the store failed loading the overview.
         */
        let mirror = Mirror(reflecting: state)
        return mirror.children.compactMap { $0.value as? StoreFetchingStatus }.first { $0 != .error } == nil
    }

    func fetchingFailed(for query: InsightQuery) -> Bool {
        switch query {
        case .insights:
            return fetchingOverviewHasFailed
        case .allFollowers:
            return fetchingFollowersStatus == .error
        case .allComments:
            return state.allCommentsInsightStatus == .error
        case .allTagsAndCategories:
            return state.allTagsAndCategoriesStatus == .error
        case .allAnnual:
            return state.allAnnualStatus == .error
        }
    }
}

// MARK: - Posting Activity Private Methods

private extension StatsInsightsStore {
    private func getMonthlyPostingActivityFor(date: Date, postingEventsDates: [Date: PostingStreakEvent]) -> [PostingStreakEvent] {

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
            // and pick out a relevant `PostingStreakEvent` from data we have or return
            // an empty one.
            .compactMap { (day: Int) -> PostingStreakEvent? in
                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                    return nil
                }

                if let postingEvent = postingEventsDates[date] {
                    return postingEvent
                }

                return PostingStreakEvent(date: date, postCount: 0)
        }

        return mappedMonth

    }

    private func getPostingEventsDates() -> [Date: PostingStreakEvent] {
        guard let postingEvents = state.postingActivity?.postingEvents else {
            return [:]
        }

        var dictionary: [Date: PostingStreakEvent] = [:]
        for event in postingEvents {
            dictionary[event.date] = event
        }
        return dictionary
    }
}
