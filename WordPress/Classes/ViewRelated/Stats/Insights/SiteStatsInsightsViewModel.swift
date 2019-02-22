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
                tableRows.append(LatestPostSummaryRow(summaryData: store.getLastPostInsight(),
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .allTimeStats:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.allTimeStats))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createAllTimeStatsRows()))
            case .followersTotals:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.followerTotals))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createTotalFollowersRows()))
            case .mostPopularDayAndHour:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.mostPopularStats))
                tableRows.append(SimpleTotalsStatsRow(dataRows: createMostPopularStatsRows()))
            case .tagsAndCategories:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.tagsAndCategories))
                tableRows.append(TopTotalsInsightStatsRow(itemSubtitle: TagsAndCategories.itemSubtitle,
                                                   dataSubtitle: TagsAndCategories.dataSubtitle,
                                                   dataRows: createTagsAndCategoriesRows(),
                                                   siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .annualSiteStats:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.annualSiteStats))
                tableRows.append(createAnnualSiteStatsRow())
            case .comments:
                tableRows.append(CellHeaderRow(title: InsightsHeaders.comments))
                tableRows.append(createCommentsRow())
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

    struct InsightsHeaders {
        static let latestPostSummary = NSLocalizedString("Latest Post Summary", comment: "Insights latest post summary header")
        static let allTimeStats = NSLocalizedString("All Time Stats", comment: "Insights 'All Time Stats' header")
        static let mostPopularStats = NSLocalizedString("Most Popular Time", comment: "Insights 'Most Popular Time' header")
        static let followerTotals = NSLocalizedString("Follower Totals", comment: "Insights 'Follower Totals' header")
        static let publicize = NSLocalizedString("Publicize", comment: "Insights 'Publicize' header")
        static let todaysStats = NSLocalizedString("Today's Stats", comment: "Insights 'Today's Stats' header")
        static let postingActivity = NSLocalizedString("Posting Activity", comment: "Insights 'Posting Activity' header")
        static let comments = NSLocalizedString("Comments", comment: "Insights 'Comments' header")
        static let followers = NSLocalizedString("Followers", comment: "Insights 'Followers' header")
        static let tagsAndCategories = NSLocalizedString("Tags and Categories", comment: "Insights 'Tags and Categories' header")
        static let annualSiteStats = NSLocalizedString("Annual Site Stats", comment: "Insights 'Annual Site Stats' header")
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
        static let percentOfViews = NSLocalizedString("%i%% of views", comment: "'Most Popular Time' label displaying percent of views. %i is the percent value.")
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

    struct Comments {
        static let dataSubtitle = NSLocalizedString("Comments", comment: "Label for comment count, either by author or post.")
    }

    enum CommentType {
        case author
        case post

        var title: String {
            switch self {
            case .author:
                return NSLocalizedString("Authors", comment: "Label for comments by author")
            case .post:
                return NSLocalizedString("Posts and Pages", comment: "Label for comments by posts and pages")
            }
        }

        var itemSubtitle: String {
            switch self {
            case .author:
                return NSLocalizedString("Author", comment: "Author label for list of commenters.")
            case .post:
                return NSLocalizedString("Title", comment: "Title label for list of posts.")
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

    struct TagsAndCategories {
        static let itemSubtitle = NSLocalizedString("Title", comment: "'Tags and Categories' label for the tag/category name.")
        static let dataSubtitle = NSLocalizedString("Views", comment: "'Tags and Categories' label for tag/category number of views.")
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
            dataRows.append(StatsTotalRowData.init(name: FollowerType.wordPressDotCom.title,
                                                   data: totalDotComFollowers.abbreviatedString(),
                                                   icon: FollowerTotals.wordPressIcon))
        }

        if let totalEmailFollowers = store.getEmailFollowers()?.emailFollowersCount,
            totalEmailFollowers > 0 {
            dataRows.append(StatsTotalRowData.init(name: FollowerType.email.title,
                                                   data: totalEmailFollowers.abbreviatedString(),
                                                   icon: FollowerTotals.emailIcon))
        }

        if let publicize = store.getPublicize(), !publicize.publicizeServices.isEmpty {
            let publicizeSum = publicize.publicizeServices.reduce(0) { $0 + $1.followers }

            dataRows.append(StatsTotalRowData.init(name: FollowerTotals.socialTitle,
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

            tabTitle = CommentType.author.title
            itemSubtitle = CommentType.author.itemSubtitle

            rowItems = authors.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  userIconURL: $0.iconURL,
                                  showDisclosure: false)
            }
        case .post:
            let posts = commentsInsight?.topPosts ?? []

            tabTitle = CommentType.post.title
            itemSubtitle = CommentType.post.itemSubtitle

            rowItems = posts.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  showDisclosure: true,
                                  disclosureURL: $0.postURL)

            }
        }

        return TabData(tabTitle: tabTitle,
                       itemSubtitle: itemSubtitle,
                       dataSubtitle: Comments.dataSubtitle,
                       dataRows: rowItems)
    }

    func createFollowersRow() -> TabbedTotalsStatsRow {
        return TabbedTotalsStatsRow(tabsData: [tabDataForFollowerType(.wordPressDotCom),
                                               tabDataForFollowerType(.email)],
                                    siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                                    showTotalCount: true)
    }

    func tabDataForFollowerType(_ followerType: FollowerType) -> TabData {

        var tabTitle: String
        var followers: [StatsFollower]?
        var totalFollowers: Int?

        switch followerType {
        case .wordPressDotCom:

            tabTitle = FollowerType.wordPressDotCom.title
            followers = store.getDotComFollowers()?.topDotComFollowers
            totalFollowers = store.getDotComFollowers()?.dotComFollowersCount
        case .email:

            tabTitle = FollowerType.email.title
            followers = store.getEmailFollowers()?.topEmailFollowers
            totalFollowers = store.getEmailFollowers()?.emailFollowersCount
        }

        let totalCount = String(format: Followers.totalFollowers,
                                tabTitle,
                                (totalFollowers ?? 0).abbreviatedString())

        let followersData = followers?.compactMap {
            return StatsTotalRowData(name: $0.name,
                                     data: $0.subscribedDate.relativeStringInPast(),
                                     userIconURL: $0.avatarURL)
        }

        return TabData(tabTitle: tabTitle,
                       itemSubtitle: Followers.itemSubtitle,
                       dataSubtitle: Followers.dataSubtitle,
                       totalCount: totalCount,
                       dataRows: followersData ?? [])
    }

}
