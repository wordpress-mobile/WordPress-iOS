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
                tableRows.append(CellHeaderRow(title: StatSection.insightsLatestPostSummary.title))
                tableRows.append(LatestPostSummaryRow(summaryData: store.getLastPostInsight(),
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .allTimeStats:
                tableRows.append(CellHeaderRow(title: StatSection.insightsAllTime.title))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createAllTimeStatsRows()))
            case .followersTotals:
                tableRows.append(CellHeaderRow(title: StatSection.insightsFollowerTotals.title))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createTotalFollowersRows()))
            case .mostPopularDayAndHour:
                tableRows.append(CellHeaderRow(title: StatSection.insightsMostPopularTime.title))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createMostPopularStatsRows()))
            case .tagsAndCategories:
                tableRows.append(CellHeaderRow(title: StatSection.insightsTagsAndCategories.title))
                tableRows.append(TopTotalsInsightStatsRow(itemSubtitle: StatSection.insightsTagsAndCategories.itemSubtitle,
                                                   dataSubtitle: StatSection.insightsTagsAndCategories.dataSubtitle,
                                                   dataRows: createTagsAndCategoriesRows(),
                                                   siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .annualSiteStats:
                tableRows.append(CellHeaderRow(title: StatSection.insightsAnnualSiteStats.title))
                tableRows.append(createAnnualSiteStatsRow())
            case .comments:
                tableRows.append(CellHeaderRow(title: StatSection.insightsCommentsPosts.title))
                tableRows.append(createCommentsRow())
            case .followers:
                tableRows.append(CellHeaderRow(title: StatSection.insightsFollowersWordPress.title))
                tableRows.append(createFollowersRow())
            case .todaysStats:
                tableRows.append(CellHeaderRow(title: StatSection.insightsTodaysStats.title))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createTodaysStatsRows()))
            case .postingActivity:
                tableRows.append(CellHeaderRow(title: StatSection.insightsPostingActivity.title))
                tableRows.append(createPostingActivityRow())
            case .publicize:
                tableRows.append(CellHeaderRow(title: StatSection.insightsPublicize.title))
                tableRows.append(SimpleTotalsStatsSubtitlesRow(itemSubtitle: StatSection.insightsPublicize.itemSubtitle,
                                                               dataSubtitle: StatSection.insightsPublicize.dataSubtitle,
                                                               dataRows: createPublicizeRows()))
            }
        }

        tableRows.append(TableFooterRow())

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
        static let percentOfViews = NSLocalizedString("%i%% of views", comment: "'Most Popular Time' label displaying percent of views. %i is the percent value.")
    }

    struct FollowerTotals {
        static let wordPress = NSLocalizedString("WordPress.com", comment: "Label for WordPress.com followers")
        static let email = NSLocalizedString("Email", comment: "Label for email followers")
        static let social = NSLocalizedString("Social", comment: "Follower Totals label for social media followers")
        static let wordPressIcon = Style.imageForGridiconType(.mySites)
        static let emailIcon = Style.imageForGridiconType(.mail)
        static let socialIcon = Style.imageForGridiconType(.share)
    }

    struct TodaysStats {
        static let viewsTitle = NSLocalizedString("Views", comment: "Today's Stats 'Views' label")
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "Today's Stats 'Visitors' label")
        static let likesTitle = NSLocalizedString("Likes", comment: "Today's Stats 'Likes' label")
        static let likesIcon = Style.imageForGridiconType(.star)
        static let commentsTitle = NSLocalizedString("Comments", comment: "Today's Stats 'Comments' label")
        static let viewsIcon = Style.imageForGridiconType(.visible)
        static let visitorsIcon = Style.imageForGridiconType(.user)
        static let commentsIcon = Style.imageForGridiconType(.comment)
    }

    struct AnnualSiteStats {
        static let totalPosts = NSLocalizedString("Total Posts", comment: "'Annual Site Stats' label for the total number of posts.")
        static let comments = NSLocalizedString("Comments", comment: "'Annual Site Stats' label for total number of comments.")
        static let likes = NSLocalizedString("Likes", comment: "'Annual Site Stats' label for total number of likes.")
        static let words = NSLocalizedString("Words", comment: "'Annual Site Stats' label for total number of words.")
        static let commentsPerPost = NSLocalizedString("Comments Per Post", comment: "'Annual Site Stats' label for average comments per post.")
        static let likesPerPost = NSLocalizedString("Likes Per Post", comment: "'Annual Site Stats' label for average likes per post.")
        static let wordsPerPost = NSLocalizedString("Words Per Post", comment: "'Annual Site Stats' label for average words per post.")
    }

    enum CommentType {
        case author
        case post
    }

    func createAllTimeStatsRows() -> [StatsTotalRowData] {
        guard let allTimeInsight = store.getAllTimeStats() else {
            return []
        }

        var dataRows = [StatsTotalRowData]()

        if allTimeInsight.postsCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.postsTitle,
                                                   data: allTimeInsight.postsCount.abbreviatedString(),
                                                   icon: AllTimeStats.postsIcon))
        }

        if allTimeInsight.viewsCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.viewsTitle,
                                                   data: allTimeInsight.viewsCount.abbreviatedString(),
                                                   icon: AllTimeStats.viewsIcon))
        }

        if allTimeInsight.visitorsCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.visitorsTitle,
                                                   data: allTimeInsight.visitorsCount.abbreviatedString(),
                                                   icon: AllTimeStats.visitorsIcon))
        }

        if allTimeInsight.bestViewsPerDayCount > 0 {
            let formattedDate = { () -> String in
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .none
                return df.string(from: allTimeInsight.bestViewsDay)
            }()

            dataRows.append(StatsTotalRowData.init(name: AllTimeStats.bestViewsEverTitle,
                                                   data: allTimeInsight.bestViewsPerDayCount.abbreviatedString(),
                                                   icon: AllTimeStats.bestViewsIcon,
                                                   nameDetail: formattedDate))
        }

        return dataRows
    }

    func createMostPopularStatsRows() -> [StatsTotalRowData] {
        guard let mostPopularStats = store.getAnnualAndMostPopularTime(),
                let mostPopularWeekday = mostPopularStats.mostPopularDayOfWeek.weekday,
                let mostPopularHour = mostPopularStats.mostPopularHour.hour,
                mostPopularStats.mostPopularDayOfWeekPercentage > 0
         else {
                return []
        }

        var calendar = Calendar.init(identifier: .gregorian)
        calendar.locale = Locale.autoupdatingCurrent

        let dayString = calendar.standaloneWeekdaySymbols[mostPopularWeekday - 1]

        let nowWithChangedHour = calendar.date(bySettingHour: mostPopularHour, minute: 0, second: 0, of: Date())

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        guard let timeModifiedDate = nowWithChangedHour else {

            return []
        }

        let timeString = timeFormatter.string(from: timeModifiedDate)

        return [StatsTotalRowData(name: dayString,
                                  data: String(format: MostPopularStats.percentOfViews,
                                               mostPopularStats.mostPopularDayOfWeekPercentage),
                                  icon: Style.imageForGridiconType(.calendar, withTint: .darkGrey)),
                StatsTotalRowData(name: timeString.replacingOccurrences(of: ":00", with: ""),
                                  data: String(format: MostPopularStats.percentOfViews,
                                               mostPopularStats.mostPopularHourPercentage),
                                  icon: Style.imageForGridiconType(.time, withTint: .darkGrey))]
        }

    func createTotalFollowersRows() -> [StatsTotalRowData] {
        var dataRows = [StatsTotalRowData]()

        if let totalDotComFollowers = store.getDotComFollowers()?.dotComFollowersCount,
            totalDotComFollowers > 0 {
            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.wordPress,
                                                   data: totalDotComFollowers.abbreviatedString(),
                                                   icon: FollowerTotals.wordPressIcon))
        }

        if let totalEmailFollowers = store.getEmailFollowers()?.emailFollowersCount,
            totalEmailFollowers > 0 {
            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.email,
                                                   data: totalEmailFollowers.abbreviatedString(),
                                                   icon: FollowerTotals.emailIcon))
        }

        if let publicize = store.getPublicize(), !publicize.publicizeServices.isEmpty {
            let publicizeSum = publicize.publicizeServices.reduce(0) { $0 + $1.followers }

            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.social,
                                                   data: publicizeSum.abbreviatedString(),
                                                   icon: FollowerTotals.socialIcon))
        }

        return dataRows
    }

    func createPublicizeRows() -> [StatsTotalRowData] {
        guard let services = store.getPublicize()?.publicizeServices else {
            return []
        }

        return services.map {
            return StatsTotalRowData(name: $0.name,
                                     data: $0.followers.abbreviatedString(),
                                     socialIconURL: $0.iconURL)
        }
    }

    func createTodaysStatsRows() -> [StatsTotalRowData] {
        guard let todaysStats = store.getTodaysStats() else {
            return []
        }
        var dataRows = [StatsTotalRowData]()

        if todaysStats.viewsCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.viewsTitle,
                                                   data: todaysStats.viewsCount.abbreviatedString(),
                                                   icon: TodaysStats.viewsIcon))
        }

        if todaysStats.visitorsCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.visitorsTitle,
                                                   data: todaysStats.visitorsCount.abbreviatedString(),
                                                   icon: TodaysStats.visitorsIcon))
        }

        if todaysStats.likesCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.likesTitle,
                                                   data: todaysStats.likesCount.abbreviatedString(),
                                                   icon: TodaysStats.likesIcon))
        }

        if todaysStats.commentsCount > 0 {
            dataRows.append(StatsTotalRowData.init(name: TodaysStats.commentsTitle,
                                                   data: todaysStats.commentsCount.abbreviatedString(),
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

    func createTagsAndCategoriesRows() -> [StatsTotalRowData] {
        guard let tagsAndCategories = store.getTopTagsAndCategories()?.topTagsAndCategories else {
            return []
        }

        return tagsAndCategories.map {
            let viewsCount = $0.viewsCount ?? 0

            return StatsTotalRowData(name: $0.name,
                                     data: viewsCount.abbreviatedString(),
                                     dataBarPercent: Float(viewsCount) / Float(tagsAndCategories.first?.viewsCount ?? 1),
                                     icon: tagsAndCategoriesIconForKind($0.kind),
                                     showDisclosure: true,
                                     disclosureURL: $0.url,
                                     childRows: childRowsForItems($0.children),
                                     statSection: .insightsTagsAndCategories)
        }
    }

    func tagsAndCategoriesIconForKind(_ kind: StatsTagAndCategory.Kind) -> UIImage? {
        switch kind {
        case .folder:
            return Style.imageForGridiconType(.folderMultiple)
        case .category:
            return Style.imageForGridiconType(.folder)
        case .tag:
            return Style.imageForGridiconType(.tag)
        }
    }

    func childRowsForItems(_ children: [StatsTagAndCategory]) -> [StatsTotalRowData] {
        return children.map {
            StatsTotalRowData.init(name: $0.name,
                                   data: "",
                                   icon: tagsAndCategoriesIconForKind($0.kind),
                                   showDisclosure: true,
                                   disclosureURL: $0.url)
        }
    }

    func createAnnualSiteStatsRow() -> AnnualSiteStatsRow {
        guard let annualInsights = store.getAnnualAndMostPopularTime(),
            annualInsights.annualInsightsTotalPostsCount > 0 else {
                return AnnualSiteStatsRow(totalPostsRowData: nil, totalsDataRows: nil, averagesDataRows: nil)
        }

        // Total Posts row
        let totalPostsRowData = StatsTotalRowData(name: AnnualSiteStats.totalPosts,
                                                  data: annualInsights.annualInsightsTotalPostsCount.abbreviatedString())

        // Totals rows
        let totalCommentsRow = StatsTotalRowData(name: AnnualSiteStats.comments,
                                                 data: annualInsights.annualInsightsTotalCommentsCount.abbreviatedString())
        let totalLikesRow = StatsTotalRowData(name: AnnualSiteStats.likes,
                                              data: annualInsights.annualInsightsTotalLikesCount.abbreviatedString())
        let totalWordsRow = StatsTotalRowData(name: AnnualSiteStats.words,
                                              data: annualInsights.annualInsightsTotalWordsCount.abbreviatedString())
        let totalsDataRows = [totalCommentsRow, totalLikesRow, totalWordsRow]

        // Averages rows
        let averageCommentsRow = StatsTotalRowData(name: AnnualSiteStats.commentsPerPost,
                                                   data: annualInsights.annualInsightsAverageCommentsCount.abbreviatedString())
        let averageLikesRow = StatsTotalRowData(name: AnnualSiteStats.likesPerPost,
                                                data: annualInsights.annualInsightsAverageLikesCount.abbreviatedString())
        let averageWordsRow = StatsTotalRowData(name: AnnualSiteStats.wordsPerPost,
                                                data: annualInsights.annualInsightsAverageWordsCount.abbreviatedString())
        let averageDataRows = [averageCommentsRow, averageLikesRow, averageWordsRow]

        return AnnualSiteStatsRow(totalPostsRowData: totalPostsRowData,
                                  totalsDataRows: totalsDataRows,
                                  averagesDataRows: averageDataRows)

    }

    func createCommentsRow() -> TabbedTotalsStatsRow {
        return TabbedTotalsStatsRow(tabsData: [tabDataForCommentType(.author),
                                               tabDataForCommentType(.post)],
                                    siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                                    showTotalCount: false)
    }

    func tabDataForCommentType(_ commentType: CommentType) -> TabData {
        let commentsInsight = store.getTopCommentsInsight()

        var tabTitle: String
        var itemSubtitle: String
        var rowItems: [StatsTotalRowData] = []

        switch commentType {
        case .author:
            let authors = commentsInsight?.topAuthors ?? []
            tabTitle = StatSection.insightsCommentsAuthors.tabTitle
            itemSubtitle = StatSection.insightsCommentsAuthors.itemSubtitle

            rowItems = authors.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  userIconURL: $0.iconURL,
                                  showDisclosure: false,
                                  statSection: .insightsCommentsAuthors)
            }
        case .post:
            let posts = commentsInsight?.topPosts ?? []
            tabTitle = StatSection.insightsCommentsPosts.tabTitle
            itemSubtitle = StatSection.insightsCommentsPosts.itemSubtitle

            rowItems = posts.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  showDisclosure: true,
                                  disclosureURL: $0.postURL,
                                  statSection: .insightsCommentsPosts)
            }
        }

        return TabData(tabTitle: tabTitle,
                       itemSubtitle: itemSubtitle,
                       dataSubtitle: StatSection.insightsCommentsPosts.dataSubtitle,
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
            followers = store.getDotComFollowers()?.topDotComFollowers
            totalFollowers = store.getDotComFollowers()?.dotComFollowersCount
        case .insightsFollowersEmail:
            followers = store.getEmailFollowers()?.topEmailFollowers
            totalFollowers = store.getEmailFollowers()?.emailFollowersCount
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

}
