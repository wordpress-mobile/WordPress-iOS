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
                let dataRows = createMostPopularStatsRows()

                // Don't show the subtitles if there is no data
                let itemSubtitle = dataRows.count > 0 ? MostPopularStats.itemSubtitle : nil
                let dataSubtitle = dataRows.count > 0 ? MostPopularStats.dataSubtitle : nil

                tableRows.append(CellHeaderRow(title: InsightsHeaders.mostPopularStats))
                tableRows.append(SimpleTotalsStatsSubtitlesRow(itemSubtitle: itemSubtitle,
                                                               dataSubtitle: dataSubtitle,
                                                               dataRows: dataRows))
            case .tagsAndCategories:
                DDLogDebug("Show \(insightType) here.")
            case .annualSiteStats:
                DDLogDebug("Show \(insightType) here.")
            case .comments:
                DDLogDebug("Show \(insightType) here.")
            case .followers:
                DDLogDebug("Show \(insightType) here.")
            case .todaysStats:
                DDLogDebug("Show \(insightType) here.")
            case .postingActivity:
                DDLogDebug("Show \(insightType) here.")
            case .publicize:
                DDLogDebug("Show \(insightType) here.")
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
        static let wordPressTitle = NSLocalizedString("WordPress.com", comment: "Follower Totals label for WordPress.com followers")
        static let wordPressIcon = Style.imageForGridiconType(.mySites)
        static let emailTitle = NSLocalizedString("Email", comment: "Follower Totals label for email followers")
        static let emailIcon = Style.imageForGridiconType(.mail)
        static let socialTitle = NSLocalizedString("Social", comment: "Follower Totals label for social media followers")
        static let socialIcon = Style.imageForGridiconType(.share)
    }

    func createAllTimeStatsRows() -> [StatsTotalRowData] {
        let allTimeStats = store.getAllTimeStats()
        var dataRows = [StatsTotalRowData]()

        // For these tests, we need the string version to display since it comes formatted (ex: numberOfPosts).
        // And we need the actual number value to test > 0 (ex: numberOfPostsValue).

        if let numberOfPosts = allTimeStats?.numberOfPosts,
            let numberOfPostsValue = allTimeStats?.numberOfPostsValue.intValue,
            numberOfPostsValue > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.postsTitle,
                                                   data: numberOfPosts,
                                                   icon: AllTimeStats.postsIcon))
        }

        if let numberOfViews = allTimeStats?.numberOfViews,
            let numberOfViewsValue = allTimeStats?.numberOfViewsValue.intValue,
            numberOfViewsValue > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.viewsTitle,
                                                   data: numberOfViews,
                                                   icon: AllTimeStats.viewsIcon))
        }

        if let numberOfVisitors = allTimeStats?.numberOfVisitors,
            let numberOfVisitorsValue = allTimeStats?.numberOfVisitorsValue.intValue,
            numberOfVisitorsValue > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.visitorsTitle,
                                                   data: numberOfVisitors,
                                                   icon: AllTimeStats.visitorsIcon))
        }

        if let bestNumberOfViews = allTimeStats?.bestNumberOfViews,
            let bestNumberOfViewsValue = allTimeStats?.bestNumberOfViewsValue.intValue,
            bestNumberOfViewsValue > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.bestViewsEverTitle,
                                                   data: bestNumberOfViews,
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

        if let totalDotComFollowers = store.getTotalDotComFollowers(),
            !totalDotComFollowers.isEmpty {
            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.wordPressTitle,
                                                   data: totalDotComFollowers,
                                                   icon: FollowerTotals.wordPressIcon))
        }

        if let totalEmailFollowers = store.getTotalEmailFollowers(),
            !totalEmailFollowers.isEmpty {
            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.emailTitle,
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

}
