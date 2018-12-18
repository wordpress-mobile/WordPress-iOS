import Foundation
import WordPressComStatsiOS
import WordPressFlux

/// The view model used by Stats Insights.
///
class SiteStatsInsightsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private let siteStatsInsightsDelegate: SiteStatsInsightsDelegate
    private let store: StatsInsightsStore
    private let insightsReceipt: Receipt
    private var changeReceipt: Receipt?
    private var insightsToShow = [InsightType]()
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Constructor

    init(insightsToShow: [InsightType],
         insightsDelegate: SiteStatsInsightsDelegate,
         store: StatsInsightsStore = StoreContainer.shared.statsInsights) {
        self.siteStatsInsightsDelegate = insightsDelegate
        self.insightsToShow = insightsToShow
        self.store = store
        insightsReceipt = store.query(.insights)

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        insightsToShow.forEach { insightType in
            switch insightType {
            case .latestPostSummary:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.latestPostSummary))
                tableRows.append(LatestPostSummaryRow(summaryData: store.getLatestPostSummary(),
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .allTimeStats:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.allTimeStats))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createAllTimeStatsRows()))
            case .followersTotals:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.followerTotals))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createTotalFollowersRows()))
            case .mostPopularDayAndHour:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.mostPopularStats))
                tableRows.append(SimpleTotalsStatsSubtitlesRow(itemSubtitle: MostPopularStats.itemSubtitle,
                                                               dataSubtitle: MostPopularStats.dataSubtitle,
                                                               dataRows: createMostPopularStatsRows()))
            case .tagsAndCategories:
                DDLogDebug("Show \(insightType) here.")
            case .annualSiteStats:
                DDLogDebug("Show \(insightType) here.")
            case .comments:
                DDLogDebug("Show \(insightType) here.")
            case .followers:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.followers))
                tableRows.append(createFollowersRow())
            case .todaysStats:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.todaysStats))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createTodaysStatsRows()))
            case .postingActivity:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.postingActivity))
                tableRows.append(createPostingActivityRow())
            case .publicize:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.publicize))
                tableRows.append(SimpleTotalsStatsSubtitlesRow(itemSubtitle: Publicize.itemSubtitle,
                                                               dataSubtitle: Publicize.dataSubtitle,
                                                               dataRows: createPublicizeRows()))
            }
        }

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshInsights() {
        ActionDispatcher.dispatch(InsightAction.refreshInsights())
    }

}

// MARK: - Private Extension

private extension SiteStatsInsightsViewModel {

    struct InsightsHeaders {
        static let latestPostSummary = NSLocalizedString("Latest Post Summary", comment: "Insights latest post summary header")
        static let allTimeStats = NSLocalizedString("All Time Stats", comment: "Insights 'All Time Stats' header")
        static let mostPopularStats = NSLocalizedString("Most Popular Day and Hour", comment: "Insights 'Most Popular Day and Hour' header")
        static let followerTotals = NSLocalizedString("Follower Totals", comment: "Insights 'Follower Totals' header")
        static let publicize = NSLocalizedString("Publicize", comment: "Insights 'Publicize' header")
        static let todaysStats = NSLocalizedString("Today's Stats", comment: "Insights 'Today's Stats' header")
        static let postingActivity = NSLocalizedString("Posting Activity", comment: "Insights 'Posting Activity' header")
        static let comments = NSLocalizedString("Comments", comment: "Insights 'Comments' header")
        static let followers = NSLocalizedString("Followers", comment: "Insights 'Followers' header")
    }

    struct AllTimeStats {
        static let postsTitle = NSLocalizedString("Posts", comment: "All Time Stats 'Posts' label")
        static let postsIcon = Style.imageForGridiconType(.posts)
        static let viewsTitle = NSLocalizedString("Views", comment: "All Time Stats 'Views' label")
        static let viewsIcon = Style.imageForGridiconType(.visible)
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "All Time Stats 'Visitors' label")
        static let visitorsIcon = Style.imageForGridiconType(.user)
        static let bestViewsEverTitle = NSLocalizedString("Best Views Ever", comment: "All Time Stats 'Best Views Ever' label")
        static let bestViewsIcon = Style.imageForGridiconType(.trophy)
    }

    struct MostPopularStats {
        static let itemSubtitle = NSLocalizedString("Day/Hour", comment: "Most Popular Day and Hour label for day and hour")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Most Popular Day and Hour label for number of views")
    }

    struct FollowerTotals {
        static let wordPressIcon = Style.imageForGridiconType(.mySites)
        static let emailIcon = Style.imageForGridiconType(.mail)
        static let socialTitle = NSLocalizedString("Social", comment: "Follower Totals label for social media followers")
        static let socialIcon = Style.imageForGridiconType(.share)
    }

    struct Followers {
        static let totalFollowers = NSLocalizedString("Total %@ Followers: %@", comment: "Label displaying total number of followers for a type. The first %@ is the type (WordPress.com or Email), the second %@ is the total.")
        static let itemSubtitle = NSLocalizedString("Follower", comment: "Followers label for list of followers.")
        static let dataSubtitle = NSLocalizedString("Since", comment: "Followers label for time period in list of follower.")
    }

    enum FollowerType {
        case wordPressDotCom
        case email

        var title: String {
            switch self {
            case .wordPressDotCom:
                return NSLocalizedString("WordPress.com", comment: "Label for WordPress.com followers")
            case .email:
                return NSLocalizedString("Email", comment: "Label for email followers")
            }
        }
    }

    struct Publicize {
        static let itemSubtitle = NSLocalizedString("Service", comment: "Publicize label for connected service")
        static let dataSubtitle = NSLocalizedString("Followers", comment: "Publicize label for number of followers")
    }

    struct TodaysStats {
        static let viewsTitle = NSLocalizedString("Views", comment: "Today's Stats 'Views' label")
        static let viewsIcon = Style.imageForGridiconType(.visible)
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "Today's Stats 'Visitors' label")
        static let visitorsIcon = Style.imageForGridiconType(.user)
        static let likesTitle = NSLocalizedString("Likes", comment: "Today's Stats 'Likes' label")
        static let likesIcon = Style.imageForGridiconType(.star)
        static let commentsTitle = NSLocalizedString("Comments", comment: "Today's Stats 'Comments' label")
        static let commentsIcon = Style.imageForGridiconType(.comment)
    }

    func createAllTimeStatsRows() -> [StatsTotalRowData] {
        let allTimeStats = store.getAllTimeStats()
        var dataRows = [StatsTotalRowData]()

        if let numberOfPosts = allTimeStats?.numberOfPostsValue.doubleValue,
            numberOfPosts > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.postsTitle,
                                                   data: numberOfPosts.abbreviatedString(),
                                                   icon: AllTimeStats.postsIcon))
        }

        if let numberOfViews = allTimeStats?.numberOfViewsValue.doubleValue,
            numberOfViews > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.viewsTitle,
                                                   data: numberOfViews.abbreviatedString(),
                                                   icon: AllTimeStats.viewsIcon))
        }

        if let numberOfVisitors = allTimeStats?.numberOfVisitorsValue.doubleValue,
            numberOfVisitors > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.visitorsTitle,
                                                   data: numberOfVisitors.abbreviatedString(),
                                                   icon: AllTimeStats.visitorsIcon))
        }

        if let bestNumberOfViews = allTimeStats?.bestNumberOfViewsValue.doubleValue,
            bestNumberOfViews > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.bestViewsEverTitle,
                                                   data: bestNumberOfViews.abbreviatedString(),
                                                   icon: AllTimeStats.bestViewsIcon,
                                                   nameDetail: allTimeStats?.bestViewsOn))
        }

        return dataRows
    }

    func createMostPopularStatsRows() -> [StatsTotalRowData] {
        let mostPopularStats = store.getMostPopularStats()
        var dataRows = [StatsTotalRowData]()

        if let highestDayOfWeek = mostPopularStats?.highestDayOfWeek,
            let highestDayPercent = mostPopularStats?.highestDayPercent,
            let highestHour = mostPopularStats?.highestHour,
            let highestHourPercent = mostPopularStats?.highestHourPercent,
            let highestDayPercentValue = mostPopularStats?.highestDayPercentValue,
            highestDayPercentValue.floatValue > 0 {

            // Day
            dataRows.append(StatsTotalRowData.init(name: highestDayOfWeek, data: highestDayPercent))

            // Hour
            let trimmedHighestHour = highestHour.replacingOccurrences(of: ":00", with: "")
            dataRows.append(StatsTotalRowData.init(name: trimmedHighestHour, data: highestHourPercent))
        }

        return dataRows
    }

    func createTotalFollowersRows() -> [StatsTotalRowData] {
        var dataRows = [StatsTotalRowData]()

        // TODO: when the API returns the actual value for followers,
        // send value.abbreviatedString() to the row.

        if let totalDotComFollowers = store.getTotalDotComFollowers(),
            !totalDotComFollowers.isEmpty {
            dataRows.append(StatsTotalRowData.init(name: FollowerType.wordPressDotCom.title,
                                                   data: totalDotComFollowers,
                                                   icon: FollowerTotals.wordPressIcon))
        }

        if let totalEmailFollowers = store.getTotalEmailFollowers(),
            !totalEmailFollowers.isEmpty {
            dataRows.append(StatsTotalRowData.init(name: FollowerType.email.title,
                                                   data: totalEmailFollowers,
                                                   icon: FollowerTotals.emailIcon))
        }

        if let totalPublicizeFollowers = store.getTotalPublicizeFollowers(),
            !totalPublicizeFollowers.isEmpty {
            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.socialTitle,
                                                   data: totalPublicizeFollowers,
                                                   icon: FollowerTotals.socialIcon))
        }

        return dataRows
    }

    func createPublicizeRows() -> [StatsTotalRowData] {
        let publicize = store.getPublicize()
        var dataRows = [StatsTotalRowData]()

        // TODO: when the API returns the actual value for followers,
        // send value.abbreviatedString() to the row.

        publicize?.forEach { item in
            dataRows.append(StatsTotalRowData.init(name: item.label, data: item.value, socialIconURL: item.iconURL))
        }

        return dataRows
    }

    func createTodaysStatsRows() -> [StatsTotalRowData] {
        let todaysStats = store.getTodaysStats()
        var dataRows = [StatsTotalRowData]()

        if let views = todaysStats?.viewsValue.doubleValue,
            views > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.viewsTitle,
                                                   data: views.abbreviatedString(),
                                                   icon: TodaysStats.viewsIcon))
        }

        if let visitors = todaysStats?.visitorsValue.doubleValue,
            visitors > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.visitorsTitle,
                                                   data: visitors.abbreviatedString(),
                                                   icon: TodaysStats.visitorsIcon))
        }

        if let likes = todaysStats?.likesValue.doubleValue,
            likes > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.likesTitle,
                                                   data: likes.abbreviatedString(),
                                                   icon: TodaysStats.likesIcon))
        }

        if let comments = todaysStats?.commentsValue.doubleValue,
            comments > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.commentsTitle,
                                                   data: comments.abbreviatedString(),
                                                   icon: TodaysStats.commentsIcon))
        }

        return dataRows
    }

    func createPostingActivityRow() -> PostingActivityRow {
        var monthsData = [[PostingActivityDayData]]()

        if let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) {
            monthsData.append(store.getMonthlyPostingActivityFor(date: twoMonthsAgo))
        }

        if let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
            monthsData.append(store.getMonthlyPostingActivityFor(date: oneMonthAgo))
        }

        monthsData.append(store.getMonthlyPostingActivityFor(date: Date()))

        return PostingActivityRow(monthsData: monthsData, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }

    func createFollowersRow() -> TabbedTotalsStatsRow {
        return TabbedTotalsStatsRow(tabsData: [tabDataForFollowerType(.wordPressDotCom),
                                               tabDataForFollowerType(.email)],
                                    siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                                    showTotalCount: true)
    }

    func tabDataForFollowerType(_ followerType: FollowerType) -> TabData {

        var tabTitle: String
        var followers: [StatsItem]?
        var totalFollowers: String

        switch followerType {
        case .wordPressDotCom:
            tabTitle = FollowerType.wordPressDotCom.title
            followers = store.getTopDotComFollowers()
            totalFollowers = store.getTotalDotComFollowers() ?? ""
        case .email:
            tabTitle = FollowerType.email.title
            followers = store.getTopEmailFollowers()
            totalFollowers = store.getTotalEmailFollowers() ?? ""
        }

        let totalCount = String(format: Followers.totalFollowers,
                                tabTitle,
                                totalFollowers)

        var rows = [StatsTotalRowData]()

        followers?.forEach { follower in
            rows.append(StatsTotalRowData.init(name: follower.label,
                                               data: follower.value,
                                               userIconURL: follower.iconURL,
                                               siteStatsInsightsDelegate: siteStatsInsightsDelegate))
        }

        return TabData.init(tabTitle: tabTitle,
                            itemSubtitle: Followers.itemSubtitle,
                            dataSubtitle: Followers.dataSubtitle,
                            totalCount: totalCount,
                            dataRows: rows)
    }

}
