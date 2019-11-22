import Foundation
import WordPressFlux

/// The view model used by Stats Insights.
///
class SiteStatsInsightsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsReceipt: Receipt?
    private var insightsChangeReceipt: Receipt?
    private var insightsToShow = [InsightType]()

    private var periodReceipt: Receipt?

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Constructor

    init(insightsToShow: [InsightType],
         insightsDelegate: SiteStatsInsightsDelegate) {
        self.siteStatsInsightsDelegate = insightsDelegate
        self.insightsToShow = insightsToShow

        insightsChangeReceipt = insightsStore.onChange { [weak self] in
            self?.emitChange()
        }
    }

    func fetchInsights() {
        insightsReceipt = insightsStore.query(.insights)
    }

    // MARK: - Refresh Data

    func refreshInsights() {
        if !insightsStore.isFetchingOverview {
            ActionDispatcher.dispatch(InsightAction.refreshInsights)
        }
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        if insightsToShow.isEmpty ||
            (insightsStore.fetchingFailed(for: .insights) && !containsCachedData()) {
            return ImmuTable.Empty
        }

        insightsToShow.forEach { insightType in
            let errorBlock = {
                return StatsErrorRow(rowStatus: .error, statType: .insights)
            }

            switch insightType {
            case .customize:
                tableRows.append(CustomizeInsightsRow(siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .latestPostSummary:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsLatestPostSummary,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .latestPostSummary,
                                        type: .insights,
                                        status: insightsStore.lastPostSummaryStatus,
                                        block: {
                                            return LatestPostSummaryRow(summaryData: insightsStore.getLastPostInsight(),
                                                                        chartData: insightsStore.getPostStats(),
                                                                        siteStatsInsightsDelegate: siteStatsInsightsDelegate)
                }, loading: {
                    return StatsGhostChartImmutableRow()
                }, error: errorBlock))
            case .allTimeStats:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsAllTime,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .allTimeStats,
                                        type: .insights,
                                        status: insightsStore.allTimeStatus,
                                        block: {
                                            return TwoColumnStatsRow(dataRows: createAllTimeStatsRows(),
                                                                     statSection: .insightsAllTime,
                                                                     siteStatsInsightsDelegate: nil)
                }, loading: {
                    return StatsGhostTwoColumnImmutableRow()
                }, error: errorBlock))
            case .followersTotals:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsFollowerTotals,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .followersTotals,
                                        type: .insights,
                                        status: insightsStore.followersTotalsStatus,
                                        block: {
                                            return TwoColumnStatsRow(dataRows: createTotalFollowersRows(),
                                                                     statSection: .insightsFollowerTotals,
                                                                     siteStatsInsightsDelegate: nil)
                }, loading: {
                    return StatsGhostTwoColumnImmutableRow()
                }, error: errorBlock))
            case .mostPopularTime:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsMostPopularTime,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .mostPopularTime,
                                        type: .insights,
                                        status: insightsStore.annualAndMostPopularTimeStatus,
                                        block: {
                                            return TwoColumnStatsRow(dataRows: createMostPopularStatsRows(),
                                                                     statSection: .insightsMostPopularTime,
                                                                     siteStatsInsightsDelegate: nil)
                }, loading: {
                    return StatsGhostTwoColumnImmutableRow()
                }, error: errorBlock))
            case .tagsAndCategories:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsTagsAndCategories,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .tagsAndCategories,
                                        type: .insights,
                                        status: insightsStore.tagsAndCategoriesStatus,
                                        block: {
                                            return TopTotalsInsightStatsRow(itemSubtitle: StatSection.insightsTagsAndCategories.itemSubtitle,
                                                                            dataSubtitle: StatSection.insightsTagsAndCategories.dataSubtitle,
                                                                            dataRows: createTagsAndCategoriesRows(),
                                                                            siteStatsInsightsDelegate: siteStatsInsightsDelegate)
                }, loading: {
                    return StatsGhostTopImmutableRow()
                }, error: errorBlock))
            case .annualSiteStats:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsAnnualSiteStats,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .annualSiteStats,
                                        type: .insights,
                                        status: insightsStore.annualAndMostPopularTimeStatus,
                                        block: {
                                            return TwoColumnStatsRow(dataRows: createAnnualRows(),
                                                                     statSection: .insightsAnnualSiteStats,
                                                                     siteStatsInsightsDelegate: siteStatsInsightsDelegate)
                }, loading: {
                    return StatsGhostTwoColumnImmutableRow()
                }, error: errorBlock))
            case .comments:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsCommentsPosts,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .comments,
                                        type: .insights,
                                        status: insightsStore.commentsInsightStatus,
                                        block: {
                                            return createCommentsRow()
                }, loading: {
                    return StatsGhostTabbedImmutableRow()
                }, error: errorBlock))
            case .followers:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsFollowersWordPress,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .followers,
                                        type: .insights,
                                        status: insightsStore.followersTotalsStatus,
                                        block: {
                                            return createFollowersRow()
                }, loading: {
                    return StatsGhostTabbedImmutableRow()
                }, error: errorBlock))
            case .todaysStats:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsTodaysStats,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .todaysStats,
                                        type: .insights,
                                        status: insightsStore.todaysStatsStatus,
                                        block: {
                                            return TwoColumnStatsRow(dataRows: createTodaysStatsRows(),
                                                                     statSection: .insightsTodaysStats,
                                                                     siteStatsInsightsDelegate: nil)
                }, loading: {
                    return StatsGhostTwoColumnImmutableRow()
                }, error: errorBlock))
            case .postingActivity:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsPostingActivity,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .postingActivity,
                                        type: .insights,
                                        status: insightsStore.postingActivityStatus,
                                        block: {
                                            return createPostingActivityRow()
                }, loading: {
                    return StatsGhostPostingActivitiesImmutableRow()
                }, error: errorBlock))
            case .publicize:
                tableRows.append(InsightCellHeaderRow(statSection: StatSection.insightsPublicize,
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
                tableRows.append(blocks(for: .publicize,
                                        type: .insights,
                                        status: insightsStore.publicizeFollowersStatus,
                                        block: {
                                            return TopTotalsInsightStatsRow(itemSubtitle: StatSection.insightsPublicize.itemSubtitle,
                                                                            dataSubtitle: StatSection.insightsPublicize.dataSubtitle,
                                                                            dataRows: createPublicizeRows(),
                                                                            siteStatsInsightsDelegate: nil)
                }, loading: {
                    return StatsGhostTopImmutableRow()
                }, error: errorBlock))
            default:
                break
            }
        }

        tableRows.append(TableFooterRow())
        tableRows.append(AddInsightRow(dataRow: createAddInsightRow(), siteStatsInsightsDelegate: siteStatsInsightsDelegate))

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    func isFetchingOverview() -> Bool {
        return insightsStore.isFetchingOverview
    }

    func fetchingFailed() -> Bool {
        return insightsStore.fetchingFailed(for: .insights)
    }

    func containsCachedData() -> Bool {
        return insightsStore.containsCachedData(for: insightsToShow)
    }

    func yearlyPostingActivity(from date: Date = Date()) -> [[PostingStreakEvent]] {
        return insightsStore.getYearlyPostingActivityFrom(date: date)
    }

    func annualInsightsYear() -> Int? {
        return insightsStore.getAnnualAndMostPopularTime()?.annualInsightsYear
    }

    func updateInsightsToShow(insights: [InsightType]) {
        insightsToShow = insights
    }

}

// MARK: - Private Extension

private extension SiteStatsInsightsViewModel {

    struct AllTimeStats {
        static let postsTitle = NSLocalizedString("Posts", comment: "All Time Stats 'Posts' label")
        static let viewsTitle = NSLocalizedString("Views", comment: "All Time Stats 'Views' label")
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "All Time Stats 'Visitors' label")
        static let bestViewsEverTitle = NSLocalizedString("Best views ever", comment: "All Time Stats 'Best views ever' label")
    }

    struct MostPopularStats {
        static let bestDay = NSLocalizedString("Best Day", comment: "'Best Day' label for Most Popular stat.")
        static let bestHour = NSLocalizedString("Best Hour", comment: "'Best Hour' label for Most Popular stat.")
    }

    struct FollowerTotals {
        static let total = NSLocalizedString("Total", comment: "Label for total followers")
        static let wordPress = NSLocalizedString("WordPress.com", comment: "Label for WordPress.com followers")
        static let email = NSLocalizedString("Email", comment: "Label for email followers")
        static let social = NSLocalizedString("Social", comment: "Follower Totals label for social media followers")
    }

    struct TodaysStats {
        static let viewsTitle = NSLocalizedString("Views", comment: "Today's Stats 'Views' label")
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "Today's Stats 'Visitors' label")
        static let likesTitle = NSLocalizedString("Likes", comment: "Today's Stats 'Likes' label")
        static let commentsTitle = NSLocalizedString("Comments", comment: "Today's Stats 'Comments' label")
    }

    func createAllTimeStatsRows() -> [StatsTwoColumnRowData] {
        guard let allTimeInsight = insightsStore.getAllTimeStats() else {
            return []
        }

        let totalCounts = allTimeInsight.viewsCount +
                          allTimeInsight.visitorsCount +
                          allTimeInsight.postsCount +
                          allTimeInsight.bestViewsPerDayCount

        guard totalCounts > 0 else {
            return []
        }

        var dataRows = [StatsTwoColumnRowData]()

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: AllTimeStats.viewsTitle,
                                                   leftColumnData: allTimeInsight.viewsCount.abbreviatedString(),
                                                   rightColumnName: AllTimeStats.visitorsTitle,
                                                   rightColumnData: allTimeInsight.visitorsCount.abbreviatedString()))

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: AllTimeStats.postsTitle,
                                                   leftColumnData: allTimeInsight.postsCount.abbreviatedString(),
                                                   rightColumnName: AllTimeStats.bestViewsEverTitle,
                                                   rightColumnData: allTimeInsight.bestViewsPerDayCount.abbreviatedString()))

        return dataRows
    }

    func createMostPopularStatsRows() -> [StatsTwoColumnRowData] {
        guard let mostPopularStats = insightsStore.getAnnualAndMostPopularTime(),
            var mostPopularWeekday = mostPopularStats.mostPopularDayOfWeek.weekday,
            let mostPopularHour = mostPopularStats.mostPopularHour.hour,
            mostPopularStats.mostPopularDayOfWeekPercentage > 0
            else {
                return []
        }

        var calendar = Calendar.init(identifier: .gregorian)
        calendar.locale = Locale.autoupdatingCurrent

        // Back up mostPopularWeekday by 1 to get correct index for standaloneWeekdaySymbols.
        mostPopularWeekday = mostPopularWeekday == 0 ? calendar.standaloneWeekdaySymbols.count - 1 : mostPopularWeekday - 1
        let dayString = calendar.standaloneWeekdaySymbols[mostPopularWeekday]

        guard let timeModifiedDate = calendar.date(bySettingHour: mostPopularHour, minute: 0, second: 0, of: Date()) else {
            return []
        }

        let timeFormatter = DateFormatter()
        timeFormatter.setLocalizedDateFormatFromTemplate("h a")

        let timeString = timeFormatter.string(from: timeModifiedDate)

        return [StatsTwoColumnRowData.init(leftColumnName: MostPopularStats.bestDay,
                                   leftColumnData: dayString,
                                   rightColumnName: MostPopularStats.bestHour,
                                   rightColumnData: timeString.uppercased())]
    }

    func createTotalFollowersRows() -> [StatsTwoColumnRowData] {
        let totalDotComFollowers = insightsStore.getDotComFollowers()?.dotComFollowersCount ?? 0
        let totalEmailFollowers = insightsStore.getEmailFollowers()?.emailFollowersCount ?? 0

        var totalPublicize = 0
        if let publicize = insightsStore.getPublicize(), !publicize.publicizeServices.isEmpty {
            totalPublicize = publicize.publicizeServices.compactMap({$0.followers}).reduce(0, +)
        }

        let totalFollowers = totalDotComFollowers + totalEmailFollowers + totalPublicize

        guard totalFollowers > 0 else {
            return []
        }

        var dataRows = [StatsTwoColumnRowData]()

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: FollowerTotals.total,
                                                   leftColumnData: totalFollowers.abbreviatedString(),
                                                   rightColumnName: FollowerTotals.wordPress,
                                                   rightColumnData: totalDotComFollowers.abbreviatedString()))

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: FollowerTotals.email,
                                                   leftColumnData: totalEmailFollowers.abbreviatedString(),
                                                   rightColumnName: FollowerTotals.social,
                                                   rightColumnData: totalPublicize.abbreviatedString()))

        return dataRows
    }

    func createPublicizeRows() -> [StatsTotalRowData] {
        guard let services = insightsStore.getPublicize()?.publicizeServices else {
            return []
        }

        return services.map {
            return StatsTotalRowData(name: $0.name,
                                     data: $0.followers.abbreviatedString(),
                                     socialIconURL: $0.iconURL,
                                     statSection: .insightsPublicize)
        }
    }

    func createTodaysStatsRows() -> [StatsTwoColumnRowData] {
        guard let todaysStats = insightsStore.getTodaysStats() else {
            return []
        }

        let totalCounts = todaysStats.viewsCount +
                          todaysStats.visitorsCount +
                          todaysStats.likesCount +
                          todaysStats.commentsCount

        guard totalCounts > 0 else {
            return []
        }

        var dataRows = [StatsTwoColumnRowData]()

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: TodaysStats.viewsTitle,
                                                   leftColumnData: todaysStats.viewsCount.abbreviatedString(),
                                                   rightColumnName: TodaysStats.visitorsTitle,
                                                   rightColumnData: todaysStats.visitorsCount.abbreviatedString()))

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: TodaysStats.likesTitle,
                                                   leftColumnData: todaysStats.likesCount.abbreviatedString(),
                                                   rightColumnName: TodaysStats.commentsTitle,
                                                   rightColumnData: todaysStats.commentsCount.abbreviatedString()))

        return dataRows
    }

    func createPostingActivityRow() -> PostingActivityRow {
        var monthsData = [[PostingStreakEvent]]()

        if let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) {
            monthsData.append(insightsStore.getMonthlyPostingActivityFor(date: twoMonthsAgo))
        }

        if let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
            monthsData.append(insightsStore.getMonthlyPostingActivityFor(date: oneMonthAgo))
        }

        monthsData.append(insightsStore.getMonthlyPostingActivityFor(date: Date()))

        return PostingActivityRow(monthsData: monthsData, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }

    func createTagsAndCategoriesRows() -> [StatsTotalRowData] {
        guard let tagsAndCategories = insightsStore.getTopTagsAndCategories()?.topTagsAndCategories else {
            return []
        }

        return tagsAndCategories.map {
            let viewsCount = $0.viewsCount ?? 0

            return StatsTotalRowData(name: $0.name,
                                     data: viewsCount.abbreviatedString(),
                                     dataBarPercent: Float(viewsCount) / Float(tagsAndCategories.first?.viewsCount ?? 1),
                                     icon: StatsDataHelper.tagsAndCategoriesIconForKind($0.kind),
                                     showDisclosure: true,
                                     disclosureURL: $0.url,
                                     childRows: StatsDataHelper.childRowsForItems($0.children),
                                     statSection: .insightsTagsAndCategories)
        }
    }

    func createAnnualRows() -> [StatsTwoColumnRowData] {

        guard let annualInsights = insightsStore.getAnnualAndMostPopularTime(),
            annualInsights.annualInsightsTotalPostsCount > 0 else {
                return []
        }

        var dataRows = [StatsTwoColumnRowData]()

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: AnnualSiteStats.year,
                                                   leftColumnData: String(annualInsights.annualInsightsYear),
                                                   rightColumnName: AnnualSiteStats.totalPosts,
                                                   rightColumnData: annualInsights.annualInsightsTotalPostsCount.abbreviatedString()))

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: AnnualSiteStats.totalComments,
                                                   leftColumnData: annualInsights.annualInsightsTotalCommentsCount.abbreviatedString(),
                                                   rightColumnName: AnnualSiteStats.commentsPerPost,
                                                   rightColumnData: Int(round(annualInsights.annualInsightsAverageCommentsCount)).abbreviatedString()))

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: AnnualSiteStats.totalLikes,
                                                   leftColumnData: annualInsights.annualInsightsTotalLikesCount.abbreviatedString(),
                                                   rightColumnName: AnnualSiteStats.likesPerPost,
                                                   rightColumnData: Int(round(annualInsights.annualInsightsAverageLikesCount)).abbreviatedString()))

        dataRows.append(StatsTwoColumnRowData.init(leftColumnName: AnnualSiteStats.totalWords,
                                                   leftColumnData: annualInsights.annualInsightsTotalWordsCount.abbreviatedString(),
                                                   rightColumnName: AnnualSiteStats.wordsPerPost,
                                                   rightColumnData: Int(round(annualInsights.annualInsightsAverageWordsCount)).abbreviatedString()))

        return dataRows

    }

    func createCommentsRow() -> TabbedTotalsStatsRow {
        return TabbedTotalsStatsRow(tabsData: [tabDataForCommentType(.insightsCommentsAuthors),
                                               tabDataForCommentType(.insightsCommentsPosts)],
                                    siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                                    showTotalCount: false)
    }

    func tabDataForCommentType(_ commentType: StatSection) -> TabData {
        let commentsInsight = insightsStore.getTopCommentsInsight()

        var rowItems: [StatsTotalRowData] = []

        // Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/11713
        // For now, don't show `View more` for Insights Comments.
        // To accomplish this, return only the max number of rows displayed on the Insights card,
        // as `View more` is added if the number of rows exceeds the max.

        switch commentType {
        case .insightsCommentsAuthors:
            let authors = commentsInsight?.topAuthors.prefix(StatsDataHelper.maxRowsToDisplay) ?? []
            rowItems = authors.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  userIconURL: $0.iconURL,
                                  showDisclosure: false,
                                  statSection: .insightsCommentsAuthors)
            }
        case .insightsCommentsPosts:
            let posts = commentsInsight?.topPosts.prefix(StatsDataHelper.maxRowsToDisplay) ?? []
            rowItems = posts.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  showDisclosure: true,
                                  disclosureURL: $0.postURL,
                                  statSection: .insightsCommentsPosts)
            }
        default:
            break
        }

        return TabData(tabTitle: commentType.tabTitle,
                       itemSubtitle: commentType.itemSubtitle,
                       dataSubtitle: commentType.dataSubtitle,
                       dataRows: rowItems)
    }

    func createFollowersRow() -> TabbedTotalsStatsRow {
        return TabbedTotalsStatsRow(tabsData: [tabDataForFollowerType(.insightsFollowersWordPress),
                                               tabDataForFollowerType(.insightsFollowersEmail)],
                                    siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                                    showTotalCount: true)
    }

    func tabDataForFollowerType(_ followerType: StatSection) -> TabData {
        let tabTitle = followerType.tabTitle
        var followers: [StatsFollower]?
        var totalFollowers: Int?

        switch followerType {
        case .insightsFollowersWordPress:
            followers = insightsStore.getDotComFollowers()?.topDotComFollowers
            totalFollowers = insightsStore.getDotComFollowers()?.dotComFollowersCount
        case .insightsFollowersEmail:
            followers = insightsStore.getEmailFollowers()?.topEmailFollowers
            totalFollowers = insightsStore.getEmailFollowers()?.emailFollowersCount
        default:
            break
        }

        let totalCount = String(format: followerType.totalFollowers, (totalFollowers ?? 0).abbreviatedString())

        let followersData = followers?.compactMap {
            return StatsTotalRowData(name: $0.name,
                                     data: $0.subscribedDate.relativeStringInPast(),
                                     userIconURL: $0.avatarURL,
                                     statSection: followerType)
        }

        return TabData(tabTitle: tabTitle,
                       itemSubtitle: followerType.itemSubtitle,
                       dataSubtitle: followerType.dataSubtitle,
                       totalCount: totalCount,
                       dataRows: followersData ?? [])
    }

    func createAddInsightRow() -> StatsTotalRowData {
        return StatsTotalRowData(name: StatSection.insightsAddInsight.title,
                                 data: "",
                                 icon: Style.imageForGridiconType(.plus, withTint: .darkGrey),
                                 statSection: .insightsAddInsight)
    }
}

extension SiteStatsInsightsViewModel: AsyncBlocksLoadable {
    typealias RowType = InsightType

    var currentStore: StatsInsightsStore {
        return insightsStore
    }
}
