import Foundation
import WordPressFlux

/// The view model used by SiteStatsDetailTableViewController to show
/// all data for a selected stat.
///
class SiteStatsDetailsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private typealias Style = WPStyleGuide.Stats

    private var statSection: StatSection?
    private weak var detailsDelegate: SiteStatsDetailsDelegate?

    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsReceipt: Receipt?
    private var insightsChangeReceipt: Receipt?

    private let periodStore = StoreContainer.shared.statsPeriod
    private var periodReceipt: Receipt?
    private var periodChangeReceipt: Receipt?

    private var selectedDate: Date?
    private var selectedPeriod: StatsPeriodUnit?
    private var postID: Int?

    private var allAnnualInsights = [StatsAnnualInsight]()

    // MARK: - Init

    init(detailsDelegate: SiteStatsDetailsDelegate) {
        self.detailsDelegate = detailsDelegate
    }

    // MARK: - Data Fetching

    func fetchDataFor(statSection: StatSection,
                      selectedDate: Date? = nil,
                      selectedPeriod: StatsPeriodUnit? = nil,
                      postID: Int? = nil) {
        self.statSection = statSection
        self.selectedDate = selectedDate
        self.selectedPeriod = selectedPeriod
        self.postID = postID

        switch statSection {
        case let statSection where StatSection.allInsights.contains(statSection):
            guard let storeQuery = queryForInsightStatSection(statSection) else {
                return
            }

            insightsChangeReceipt = insightsStore.onChange { [weak self] in
                self?.emitChange()
            }
            insightsReceipt = insightsStore.query(storeQuery)
        case let statSection where StatSection.allPeriods.contains(statSection):
            guard let storeQuery = queryForPeriodStatSection(statSection) else {
                return
            }

            periodChangeReceipt = periodStore.onChange { [weak self] in
                self?.emitChange()
            }
            periodReceipt = periodStore.query(storeQuery)
        case let statSection where StatSection.allPostStats.contains(statSection):
            guard let postID = postID else {
                return
            }

            periodChangeReceipt = periodStore.onChange { [weak self] in
                self?.emitChange()
            }
            periodReceipt = periodStore.query(.postStats(postID: postID))
        default:
            break
        }
    }

    func fetchDataHasFailed() -> Bool {
        guard let statSection = statSection else {
            return true
        }

        switch statSection {
        case let statSection where StatSection.allInsights.contains(statSection):
            guard let storeQuery = queryForInsightStatSection(statSection) else {
                return true
            }
            return insightsStore.fetchingFailed(for: storeQuery)
        case let statSection where StatSection.allPeriods.contains(statSection):
            guard let storeQuery = queryForPeriodStatSection(statSection) else {
                return true
            }
            return periodStore.fetchingFailed(for: storeQuery)
        default:
            guard let postID = postID else {
                return true
            }
            return periodStore.fetchingFailed(for: .postStats(postID: postID))
        }
    }

    func storeIsFetching(statSection: StatSection) -> Bool {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return insightsStore.isFetchingAllFollowers
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return insightsStore.isFetchingComments
        case .insightsTagsAndCategories:
            return insightsStore.isFetchingTagsAndCategories
        case .insightsAnnualSiteStats:
            return insightsStore.isFetchingAnnual
        case .periodPostsAndPages:
            return periodStore.isFetchingPostsAndPages
        case .periodSearchTerms:
            return periodStore.isFetchingSearchTerms
        case .periodVideos:
            return periodStore.isFetchingVideos
        case .periodClicks:
            return periodStore.isFetchingClicks
        case .periodAuthors:
            return periodStore.isFetchingAuthors
        case .periodReferrers:
            return periodStore.isFetchingReferrers
        case .periodCountries:
            return periodStore.isFetchingCountries
        case .periodPublished:
            return periodStore.isFetchingPublished
        case .periodFileDownloads:
            return periodStore.isFetchingFileDownloads
        case .postStatsMonthsYears, .postStatsAverageViews:
            return periodStore.isFetchingPostStats(for: postID)
        default:
            return false
        }
    }

    func updateSelectedDate(_ selectedDate: Date) {
        self.selectedDate = selectedDate
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {
        guard let statSection = statSection,
            let detailsDelegate = detailsDelegate else {
                return ImmuTable.Empty
        }

        if fetchDataHasFailed() {
            return ImmuTable.Empty
        }

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            let status = statSection == .insightsFollowersWordPress ? insightsStore.allDotComFollowersStatus : insightsStore.allEmailFollowersStatus
            let type: InsightType = statSection == .insightsFollowersWordPress ? .allDotComFollowers : .allEmailFollowers
            return insightsImmuTable(for: (type, status)) {
                var rows = [ImmuTableRow]()
                let selectedIndex = statSection == .insightsFollowersWordPress ? 0 : 1
                let wpTabData = tabDataForFollowerType(.insightsFollowersWordPress)
                let emailTabData = tabDataForFollowerType(.insightsFollowersEmail)
                rows.append(DetailSubtitlesTabbedHeaderRow(tabsData: [wpTabData, emailTabData],
                                                           siteStatsDetailsDelegate: detailsDelegate,
                                                           showTotalCount: true,
                                                           selectedIndex: selectedIndex))
                let dataRows = statSection == .insightsFollowersWordPress ? wpTabData.dataRows : emailTabData.dataRows
                if dataRows.isEmpty {
                    rows.append(StatsErrorRow(rowStatus: .success, statType: .insights))
                } else {
                    rows.append(contentsOf: tabbedRowsFrom(dataRows))
                }
                return rows
            }
        case .insightsCommentsAuthors, .insightsCommentsPosts:
           return insightsImmuTable(for: (.allComments, insightsStore.allCommentsInsightStatus)) {
                var rows = [ImmuTableRow]()
                let selectedIndex = statSection == .insightsCommentsAuthors ? 0 : 1
                let authorsTabData = tabDataForCommentType(.insightsCommentsAuthors)
                let postsTabData = tabDataForCommentType(.insightsCommentsPosts)
                rows.append(DetailSubtitlesTabbedHeaderRow(tabsData: [authorsTabData, postsTabData],
                                                           siteStatsDetailsDelegate: detailsDelegate,
                                                           showTotalCount: false,
                                                           selectedIndex: selectedIndex))
                let dataRows = statSection == .insightsCommentsAuthors ? authorsTabData.dataRows : postsTabData.dataRows
                if dataRows.isEmpty {
                    rows.append(StatsErrorRow(rowStatus: .success, statType: .insights))
                } else {
                    rows.append(contentsOf: tabbedRowsFrom(dataRows))
                }
                return rows
            }
        case .insightsTagsAndCategories:
            return insightsImmuTable(for: (.allTagsAndCategories, insightsStore.allTagsAndCategoriesStatus)) {
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.insightsTagsAndCategories.itemSubtitle,
                                                     dataSubtitle: StatSection.insightsTagsAndCategories.dataSubtitle))
                rows.append(contentsOf: tagsAndCategoriesRows())
                return rows
            }
        case .insightsAnnualSiteStats:
            return insightsImmuTable(for: (.allAnnual, insightsStore.allAnnualStatus)) {
                return Array(annualRows())
            }
        case .periodPostsAndPages:
            return periodImmuTable(for: periodStore.topPostsAndPagesStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                                          dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle))
                rows.append(contentsOf: postsAndPagesRows(for: status))
                return rows
            }
        case .periodSearchTerms:
            return periodImmuTable(for: periodStore.topSearchTermsStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                     dataSubtitle: StatSection.periodSearchTerms.dataSubtitle))
                rows.append(contentsOf: searchTermsRows(for: status))
                return rows
            }
        case .periodVideos:
            return periodImmuTable(for: periodStore.topVideosStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                     dataSubtitle: StatSection.periodVideos.dataSubtitle))
                rows.append(contentsOf: videosRows(for: status))
                return rows
            }
        case .periodClicks:
            return periodImmuTable(for: periodStore.topClicksStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                     dataSubtitle: StatSection.periodClicks.dataSubtitle))
                rows.append(contentsOf: clicksRows(for: status))
                return rows
            }
        case .periodAuthors:
            return periodImmuTable(for: periodStore.topAuthorsStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                     dataSubtitle: StatSection.periodAuthors.dataSubtitle))
                rows.append(contentsOf: authorsRows(for: status))
                return rows
            }
        case .periodReferrers:
            return periodImmuTable(for: periodStore.topReferrersStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                     dataSubtitle: StatSection.periodReferrers.dataSubtitle))
                rows.append(contentsOf: referrersRows(for: status))
                return rows
            }
        case .periodCountries:
            return periodImmuTable(for: periodStore.topCountriesStatus) { status in
                var rows = [ImmuTableRow]()
                let map = countriesMap()
                if !map.data.isEmpty {
                    rows.append(CountriesMapRow(countriesMap: map))
                }
                rows.append(DetailSubtitlesCountriesHeaderRow(itemSubtitle: StatSection.periodCountries.itemSubtitle,
                                                              dataSubtitle: StatSection.periodCountries.dataSubtitle))
                rows.append(contentsOf: countriesRows(for: status))
                return rows
            }
        case .periodPublished:
            return periodImmuTable(for: periodStore.topPublishedStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: "", dataSubtitle: ""))
                rows.append(contentsOf: publishedRows(for: status))
                return rows
            }
        case .periodFileDownloads:
            return periodImmuTable(for: periodStore.topFileDownloadsStatus) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodFileDownloads.itemSubtitle,
                                                     dataSubtitle: StatSection.periodFileDownloads.dataSubtitle))
                rows.append(contentsOf: fileDownloadsRows(for: status))
                return rows
            }
        case .postStatsMonthsYears:
            return periodImmuTable(for: periodStore.postStatsFetchingStatuses(for: postID)) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesCountriesHeaderRow(itemSubtitle: StatSection.postStatsMonthsYears.itemSubtitle,
                                                              dataSubtitle: StatSection.postStatsMonthsYears.dataSubtitle))
                rows.append(contentsOf: postStatsRows(status: status))
                return rows
            }
        case .postStatsAverageViews:
            return periodImmuTable(for: periodStore.postStatsFetchingStatuses(for: postID)) { status in
                var rows = [ImmuTableRow]()
                rows.append(DetailSubtitlesCountriesHeaderRow(itemSubtitle: StatSection.postStatsAverageViews.itemSubtitle,
                                                              dataSubtitle: StatSection.postStatsAverageViews.dataSubtitle))
                rows.append(contentsOf: postStatsRows(forAverages: true, status: status))
                return rows
            }
        default:
            return ImmuTable.Empty
        }
    }

    // MARK: - Refresh Data

    func refreshFollowers() {
        ActionDispatcher.dispatch(InsightAction.refreshFollowers)
    }

    func refreshComments() {
        ActionDispatcher.dispatch(InsightAction.refreshComments)
    }

    func refreshTagsAndCategories() {
        ActionDispatcher.dispatch(InsightAction.refreshTagsAndCategories)
    }

    func refreshAnnual(selectedDate: Date) {
        self.selectedDate = selectedDate
        ActionDispatcher.dispatch(InsightAction.refreshAnnual)
    }

    func refreshPostsAndPages() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshPostsAndPages(date: selectedDate, period: selectedPeriod))
    }

    func refreshSearchTerms() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshSearchTerms(date: selectedDate, period: selectedPeriod))
    }

    func refreshVideos() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshVideos(date: selectedDate, period: selectedPeriod))
    }

    func refreshClicks() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshClicks(date: selectedDate, period: selectedPeriod))
    }

    func refreshAuthors() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshAuthors(date: selectedDate, period: selectedPeriod))
    }

    func refreshReferrers() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshReferrers(date: selectedDate, period: selectedPeriod))
    }

    func refreshCountries() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshCountries(date: selectedDate, period: selectedPeriod))
    }

    func refreshPublished() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshPublished(date: selectedDate, period: selectedPeriod))
    }

    func refreshFileDownloads() {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }
        ActionDispatcher.dispatch(PeriodAction.refreshFileDownloads(date: selectedDate, period: selectedPeriod))
    }

    func refreshPostStats() {
        guard let postID = postID else {
            return
        }

        ActionDispatcher.dispatch(PeriodAction.refreshPostStats(postID: postID))
    }

}

// MARK: - Private Extension

private extension SiteStatsDetailsViewModel {

    // MARK: - Store Queries

    func queryForInsightStatSection(_ statSection: StatSection) -> InsightQuery? {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return .allFollowers
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return .allComments
        case .insightsTagsAndCategories:
            return .allTagsAndCategories
        case .insightsAnnualSiteStats:
            return .allAnnual
        default:
            return nil
        }
    }

    func queryForPeriodStatSection(_ statSection: StatSection) -> PeriodQuery? {

        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return nil
        }

        switch statSection {
        case .periodPostsAndPages:
            return .allPostsAndPages(date: selectedDate, period: selectedPeriod)
        case .periodSearchTerms:
            return .allSearchTerms(date: selectedDate, period: selectedPeriod)
        case .periodVideos:
            return .allVideos(date: selectedDate, period: selectedPeriod)
        case .periodClicks:
            return .allClicks(date: selectedDate, period: selectedPeriod)
        case .periodAuthors:
            return .allAuthors(date: selectedDate, period: selectedPeriod)
        case .periodReferrers:
            return .allReferrers(date: selectedDate, period: selectedPeriod)
        case .periodCountries:
            return .allCountries(date: selectedDate, period: selectedPeriod)
        case .periodPublished:
            return .allPublished(date: selectedDate, period: selectedPeriod)
        case .periodFileDownloads:
            return .allFileDownloads(date: selectedDate, period: selectedPeriod)
        default:
            return nil
        }
    }

    // MARK: - Tabbed Cards

    func tabbedRowsFrom(_ commentsRowData: [StatsTotalRowData]) -> [DetailDataRow] {
        return dataRowsFor(commentsRowData)
    }

    func tabDataForFollowerType(_ followerType: StatSection) -> TabData {
        let tabTitle = followerType.tabTitle
        var followers: [StatsFollower] = []
        var totalFollowers: Int?

        switch followerType {
        case .insightsFollowersWordPress:
            followers = insightsStore.getAllDotComFollowers()?.topDotComFollowers ?? []
            totalFollowers = insightsStore.getAllDotComFollowers()?.dotComFollowersCount
        case .insightsFollowersEmail:
            followers = insightsStore.getAllEmailFollowers()?.topEmailFollowers ?? []
            totalFollowers = insightsStore.getAllEmailFollowers()?.emailFollowersCount
        default:
            break
        }

        let totalCount = String(format: followerType.totalFollowers, (totalFollowers ?? 0).abbreviatedString())

        let followersData = followers.compactMap {
            return StatsTotalRowData(name: $0.name,
                                     data: $0.subscribedDate.relativeStringInPast(),
                                     userIconURL: $0.avatarURL,
                                     statSection: followerType)
        }

        return TabData(tabTitle: tabTitle,
                       itemSubtitle: followerType.itemSubtitle,
                       dataSubtitle: followerType.dataSubtitle,
                       totalCount: totalCount,
                       dataRows: followersData)
    }

    func tabDataForCommentType(_ commentType: StatSection) -> TabData {
        let commentsInsight = insightsStore.getAllCommentsInsight()

        var rowItems: [StatsTotalRowData] = []

        switch commentType {
        case .insightsCommentsAuthors:
            let authors = commentsInsight?.topAuthors ?? []
            rowItems = authors.map {
                StatsTotalRowData(name: $0.name,
                                  data: $0.commentCount.abbreviatedString(),
                                  userIconURL: $0.iconURL,
                                  showDisclosure: false,
                                  statSection: .insightsCommentsAuthors)
            }
        case .insightsCommentsPosts:
            let posts = commentsInsight?.topPosts ?? []
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

    // MARK: - Tags and Categories

    func tagsAndCategoriesRows() -> [ImmuTableRow] {
        return expandableDataRowsFor(tagsAndCategoriesRowData())
    }

    func tagsAndCategoriesRowData() -> [StatsTotalRowData] {
        guard let tagsAndCategories = insightsStore.getAllTagsAndCategories()?.topTagsAndCategories else {
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

    // MARK: - Annual Site Stats

    func annualRows() -> [DetailDataRow] {
        return dataRowsFor(annualRowData())
    }

    func annualRowData() -> [StatsTotalRowData] {

        guard let selectedDate = selectedDate else {
            return []
        }

        allAnnualInsights = insightsStore.getAllAnnual()?.allAnnualInsights ?? []
        let selectedYear = Calendar.current.component(.year, from: selectedDate)
        let selectedYearInsights = allAnnualInsights.first { $0.year == selectedYear }

        guard let annualInsights = selectedYearInsights else {
            return []
        }

        return [StatsTotalRowData(name: AnnualSiteStats.totalPosts,
                                  data: annualInsights.totalPostsCount.abbreviatedString()),
                StatsTotalRowData(name: AnnualSiteStats.totalComments,
                                  data: annualInsights.totalCommentsCount.abbreviatedString()),
                StatsTotalRowData(name: AnnualSiteStats.commentsPerPost,
                                  data: Int(round(annualInsights.averageCommentsCount)).abbreviatedString()),
                StatsTotalRowData(name: AnnualSiteStats.totalLikes,
                                  data: annualInsights.totalLikesCount.abbreviatedString()),
                StatsTotalRowData(name: AnnualSiteStats.likesPerPost,
                                  data: Int(round(annualInsights.averageLikesCount)).abbreviatedString()),
                StatsTotalRowData(name: AnnualSiteStats.totalWords,
                                  data: annualInsights.totalWordsCount.abbreviatedString()),
                StatsTotalRowData(name: AnnualSiteStats.wordsPerPost,
                                  data: Int(round(annualInsights.averageWordsCount)).abbreviatedString())]
    }

    // MARK: - Posts and Pages

    func postsAndPagesRows(for status: StoreFetchingStatus) -> [DetailDataRow] {
        return dataRowsFor(postsAndPagesRowData(), status: status)
    }

    func postsAndPagesRowData() -> [StatsTotalRowData] {
        let postsAndPages = periodStore.getTopPostsAndPages()?.topPosts ?? []

        return postsAndPages.map {
            let icon: UIImage?

            switch $0.kind {
            case .homepage:
                icon = Style.imageForGridiconType(.house, withTint: .icon)
            case .page:
                icon = Style.imageForGridiconType(.pages, withTint: .icon)
            case .post:
                icon = Style.imageForGridiconType(.posts, withTint: .icon)
            case .unknown:
                icon = Style.imageForGridiconType(.posts, withTint: .icon)
            }

            return StatsTotalRowData(name: $0.title,
                                     data: $0.viewsCount.abbreviatedString(),
                                     postID: $0.postID,
                                     dataBarPercent: Float($0.viewsCount) / Float(postsAndPages.first!.viewsCount),
                                     icon: icon,
                                     showDisclosure: true,
                                     disclosureURL: $0.postURL,
                                     statSection: .periodPostsAndPages)
        }
    }

    // MARK: - Search Terms

    func searchTermsRows(for status: StoreFetchingStatus) -> [DetailDataRow] {
        return dataRowsFor(searchTermsRowData(), status: status)
    }

    func searchTermsRowData() -> [StatsTotalRowData] {
        guard let searchTerms = periodStore.getTopSearchTerms() else {
            return []
        }


        var mappedSearchTerms = searchTerms.searchTerms.map { StatsTotalRowData(name: $0.term,
                                                                                data: $0.viewsCount.abbreviatedString(),
                                                                                statSection: .periodSearchTerms) }

        if !mappedSearchTerms.isEmpty && searchTerms.hiddenSearchTermsCount > 0 {
            // We want to insert the "Unknown search terms" item only if there's anything to show in the first place — if the
            // section is empty, it doesn't make sense to insert it here.

            let unknownSearchTerm = StatsTotalRowData(name: NSLocalizedString("Unknown search terms",
                                                                              comment: "Search Terms label for 'unknown search terms'."),
                                                      data: searchTerms.hiddenSearchTermsCount.abbreviatedString(),
                                                      statSection: .periodSearchTerms)

            mappedSearchTerms.insert(unknownSearchTerm, at: 0)
        }

        return mappedSearchTerms
    }

    // MARK: - Videos

    func videosRows(for status: StoreFetchingStatus) -> [DetailDataRow] {
        return dataRowsFor(videosRowData(), status: status)
    }

    func videosRowData() -> [StatsTotalRowData] {
        return periodStore.getTopVideos()?.videos.map { StatsTotalRowData(name: $0.title,
                                                                          data: $0.playsCount.abbreviatedString(),
                                                                          mediaID: $0.postID as NSNumber,
                                                                          icon: Style.imageForGridiconType(.video),
                                                                          showDisclosure: true,
                                                                          statSection: .periodVideos) }
            ?? []
    }

    // MARK: - Clicks

    func clicksRows(for status: StoreFetchingStatus) -> [ImmuTableRow] {
        return expandableDataRowsFor(clicksRowData(), status: status)
    }

    func clicksRowData() -> [StatsTotalRowData] {
        return periodStore.getTopClicks()?.clicks.map {
            StatsTotalRowData(name: $0.title,
                              data: $0.clicksCount.abbreviatedString(),
                              showDisclosure: true,
                              disclosureURL: $0.iconURL,
                              childRows: $0.children.map { StatsTotalRowData(name: $0.title,
                                                                             data: $0.clicksCount.abbreviatedString(),
                                                                             showDisclosure: true,
                                                                             disclosureURL: $0.clickedURL) },
                              statSection: .periodClicks)
            } ?? []
    }

    // MARK: - Authors

    func authorsRows(for status: StoreFetchingStatus) -> [ImmuTableRow] {
        return expandableDataRowsFor(authorsRowData(), status: status)
    }

    func authorsRowData() -> [StatsTotalRowData] {
        let authors = periodStore.getTopAuthors()?.topAuthors ?? []

        return authors.map {
            StatsTotalRowData(name: $0.name,
                              data: $0.viewsCount.abbreviatedString(),
                              dataBarPercent: Float($0.viewsCount) / Float(authors.first!.viewsCount),
                              userIconURL: $0.iconURL,
                              showDisclosure: true,
                              childRows: $0.posts.map { StatsTotalRowData(name: $0.title,
                                                                          data: $0.viewsCount.abbreviatedString(),
                                                                          statSection: .periodAuthors) },
                              statSection: .periodAuthors)
        }
    }

    // MARK: - Referrers

    func referrersRows(for status: StoreFetchingStatus) -> [ImmuTableRow] {
        return expandableDataRowsFor(referrersRowData(), status: status)
    }

    func referrersRowData() -> [StatsTotalRowData] {
        let referrers = periodStore.getTopReferrers()?.referrers ?? []

        func rowDataFromReferrer(referrer: StatsReferrer) -> StatsTotalRowData {
            var icon: UIImage? = nil
            var iconURL: URL? = nil

            switch referrer.iconURL?.lastPathComponent {
            case "search-engine.png":
                icon = Style.imageForGridiconType(.search)
            case nil:
                icon = Style.imageForGridiconType(.globe)
            default:
                iconURL = referrer.iconURL
            }

            return StatsTotalRowData(name: referrer.title,
                                     data: referrer.viewsCount.abbreviatedString(),
                                     icon: icon,
                                     socialIconURL: iconURL,
                                     showDisclosure: true,
                                     disclosureURL: referrer.url,
                                     childRows: referrer.children.map { rowDataFromReferrer(referrer: $0) },
                                     statSection: .periodReferrers)
        }

        return referrers.map { rowDataFromReferrer(referrer: $0) }
    }

    // MARK: - Countries

    func countriesRows(for status: StoreFetchingStatus) -> [DetailDataRow] {
        return dataRowsFor(countriesRowData(), status: status)
    }

    func countriesRowData() -> [StatsTotalRowData] {
        return periodStore.getTopCountries()?.countries.map { StatsTotalRowData(name: $0.name,
                                                                                data: $0.viewsCount.abbreviatedString(),
                                                                                icon: UIImage(named: $0.code),
                                                                                statSection: .periodCountries) }
            ?? []
    }

    func countriesMap() -> CountriesMap {
        let countries = periodStore.getTopCountries()?.countries ?? []
        return CountriesMap(minViewsCount: countries.last?.viewsCount ?? 0,
                            maxViewsCount: countries.first?.viewsCount ?? 0,
                            data: countries.reduce([String: NSNumber]()) { (dict, country) in
                                var nextDict = dict
                                nextDict.updateValue(NSNumber(value: country.viewsCount), forKey: country.code)
                                return nextDict
        })
    }

    // MARK: - Published

    func publishedRows(for status: StoreFetchingStatus) -> [DetailDataRow] {
        return dataRowsFor(publishedRowData(), status: status)
    }

    func publishedRowData() -> [StatsTotalRowData] {
        return periodStore.getTopPublished()?.publishedPosts.map { StatsTotalRowData(name: $0.title,
                                                                                     data: "",
                                                                                     showDisclosure: true,
                                                                                     disclosureURL: $0.postURL,
                                                                                     statSection: .periodPublished) }
            ?? []
    }

    // MARK: - File Downloads

    func fileDownloadsRows(for status: StoreFetchingStatus) -> [DetailDataRow] {
        return dataRowsFor(fileDownloadsRowData(), status: status)
    }

    func fileDownloadsRowData() -> [StatsTotalRowData] {
        return periodStore.getTopFileDownloads()?.fileDownloads.map { StatsTotalRowData(name: $0.file,
                                                                                        data: $0.downloadCount.abbreviatedString(),
                                                                                        statSection: .periodFileDownloads) }
            ?? []
    }

    // MARK: - Post Stats

    func postStatsRows(forAverages: Bool = false, status: StoreFetchingStatus) -> [ImmuTableRow] {
        return expandableDataRowsFor(postStatsRowData(forAverages: forAverages), status: status)
    }

    func postStatsRowData(forAverages: Bool) -> [StatsTotalRowData] {
        let postStats = periodStore.getPostStats(for: postID)

        guard let yearsData = (forAverages ? postStats?.dailyAveragesPerMonth : postStats?.monthlyBreakdown),
            let minYear = StatsDataHelper.minYearFrom(yearsData: yearsData),
            let maxYear = StatsDataHelper.maxYearFrom(yearsData: yearsData) else {
                return []
        }

        var yearRows = [StatsTotalRowData]()

        // Create Year rows in descending order
        for year in (minYear...maxYear).reversed() {
            let months = StatsDataHelper.monthsFrom(yearsData: yearsData, forYear: year)
            let yearTotalViews = StatsDataHelper.totalViewsFrom(monthsData: months)

            let rowValue: Int = {
                if forAverages {
                    return months.count > 0 ? (yearTotalViews / months.count) : 0
                }
                return yearTotalViews
            }()

            if rowValue > 0 {
                yearRows.append(StatsTotalRowData(name: String(year),
                                                  data: rowValue.abbreviatedString(),
                                                  showDisclosure: true,
                                                  childRows: StatsDataHelper.childRowsForYear(months),
                                                  statSection: forAverages ? .postStatsAverageViews : .postStatsMonthsYears))
            }
        }

        return yearRows
    }

    // MARK: - Helpers

    func dataRowsFor(_ rowsData: [StatsTotalRowData], status: StoreFetchingStatus = .idle) -> [DetailDataRow] {
        var detailDataRows = [DetailDataRow]()

        for (idx, rowData) in rowsData.enumerated() {
            let isLastRow = idx == rowsData.endIndex-1 && status != .loading
            detailDataRows.append(DetailDataRow(rowData: rowData,
                                                detailsDelegate: detailsDelegate,
                                                hideIndentedSeparator: isLastRow,
                                                hideFullSeparator: !isLastRow))
        }

        return detailDataRows
    }

    func expandableDataRowsFor(_ rowsData: [StatsTotalRowData], status: StoreFetchingStatus = .idle) -> [ImmuTableRow] {
        var detailDataRows = [ImmuTableRow]()

        for (idx, rowData) in rowsData.enumerated() {

            // Expanded state of current row
            let expanded = rowExpanded(rowData)

            // Expanded state of next row
            let nextExpanded: Bool = {
                let nextIndex = idx + 1
                if nextIndex < rowsData.count {
                    return rowExpanded(rowsData[nextIndex])
                }
                return false
            }()

            let isLastRow = idx == rowsData.endIndex-1 && status != .loading

            // Toggle the indented separator line based on expanded states.
            // If the current row is expanded, hide the separator.
            // If the current row is not expanded, hide the separator if the next row is.
            let hideIndentedSeparator = expanded ? (expanded || isLastRow) : (nextExpanded || isLastRow)

            // Add top level parent row
            detailDataRows.append(parentRow(rowData: rowData,
                                            hideIndentedSeparator: hideIndentedSeparator,
                                            hideFullSeparator: !isLastRow,
                                            expanded: expanded))

            // Continue to next parent if not expanded.
            guard expanded, let childRowsData = rowData.childRows else {
                continue
            }

            // Add child rows
            for (idx, childRowData) in childRowsData.enumerated() {
                let isLastRow = idx == childRowsData.endIndex-1

                // If this is the last child row, toggle the full separator based on
                // next parent's expanded state to prevent duplicate lines.
                let hideFullSeparator = isLastRow ? nextExpanded : true

                // If the parent row has an icon, show the image view for the child
                // to make the child row appear "indented".
                let showImage = rowData.hasIcon

                let grandChildRowsData = childRowData.childRows ?? []

                // If this child has no children, add it as a child row.
                guard !grandChildRowsData.isEmpty else {
                    detailDataRows.append(childRow(rowData: childRowData,
                                                   hideFullSeparator: hideFullSeparator,
                                                   showImage: showImage))
                    continue
                }

                let childExpanded = rowExpanded(childRowData)

                // If this child has children, add it as a parent row.
                detailDataRows.append(parentRow(rowData: childRowData,
                                                hideIndentedSeparator: true,
                                                hideFullSeparator: !isLastRow,
                                                expanded: childExpanded))

                // If this child is not expanded, continue to next.
                guard childExpanded else {
                    continue
                }

                // Expanded state of next child row
                let nextChildExpanded: Bool = {
                    let nextIndex = idx + 1
                    if nextIndex < childRowsData.count {
                        return rowExpanded(childRowsData[nextIndex])
                    }
                    return false
                }()

                // Add grandchild rows
                for (idx, grandChildRowData) in grandChildRowsData.enumerated() {

                    // If this is the last grandchild row, toggle the full separator based on
                    // next child's expanded state to prevent duplicate lines.
                    let hideFullSeparator = (idx == grandChildRowsData.endIndex-1) ? nextChildExpanded : true

                    detailDataRows.append(childRow(rowData: grandChildRowData,
                                                   hideFullSeparator: hideFullSeparator,
                                                   showImage: showImage))
                }
            }
        }

        return detailDataRows
    }

    func childRow(rowData: StatsTotalRowData, hideFullSeparator: Bool, showImage: Bool) -> DetailExpandableChildRow {
        return DetailExpandableChildRow(rowData: rowData,
                                        detailsDelegate: detailsDelegate,
                                        hideIndentedSeparator: true,
                                        hideFullSeparator: hideFullSeparator,
                                        showImage: showImage)

    }

    func parentRow(rowData: StatsTotalRowData, hideIndentedSeparator: Bool, hideFullSeparator: Bool, expanded: Bool) -> DetailExpandableRow {
        return DetailExpandableRow(rowData: rowData,
                                   detailsDelegate: detailsDelegate,
                                   hideIndentedSeparator: hideIndentedSeparator,
                                   hideFullSeparator: hideFullSeparator,
                                   expanded: expanded)
    }

    func rowExpanded(_ rowData: StatsTotalRowData) -> Bool {
        guard let statSection = rowData.statSection else {
            return false
        }
        return StatsDataHelper.expandedRowLabelsDetails[statSection]?.contains(rowData.name) ?? false
    }

    func insightsImmuTable(for row: (type: InsightType, status: StoreFetchingStatus), rowsBlock: () -> [ImmuTableRow]) -> ImmuTable {
        if insightsStore.containsCachedData(for: row.type) {
            return ImmuTable(sections: [
                ImmuTableSection(
                    rows: rowsBlock())
            ])
        }

        var rows = [ImmuTableRow]()

        switch row.status {
        case .loading, .idle:
            rows.append(contentsOf: getGhostSequence())
        case .success:
            rows.append(contentsOf: rowsBlock())
        case .error:
            break
        }

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: rows)
        ])
    }

    func periodImmuTable(for status: StoreFetchingStatus, rowsBlock: (StoreFetchingStatus) -> [ImmuTableRow]) -> ImmuTable {
        if !Feature.enabled(.statsAsyncLoadingDWMY) {
            return ImmuTable(sections: [
                ImmuTableSection(
                    rows: rowsBlock(.idle))
            ])
        }

        var rows = [ImmuTableRow]()

        switch status {
        case .loading, .idle:
            let content = rowsBlock(status)

            // Check if the content has more than 1 row
            if content.count <= Constants.Sequence.minRowCount {
                rows.append(contentsOf: getGhostSequence())
            } else {
                rows.append(contentsOf: content)
                rows.append(StatsGhostDetailRow(hideTopBorder: true,
                                                isLastRow: true,
                                                enableTopPadding: true))
            }
        case .success:
            rows.append(contentsOf: rowsBlock(status))
        case .error:
            break
        }

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: rows)
        ])
    }

    func getGhostSequence() -> [ImmuTableRow] {
        var rows = [ImmuTableRow]()
        rows.append(StatsGhostTopHeaderImmutableRow())
        rows.append(contentsOf: (Constants.Sequence.rows).map { index in
            let isLastRow = index == Constants.Sequence.maxRowCount
            return StatsGhostDetailRow(hideTopBorder: true,
                                       isLastRow: isLastRow,
                                       enableTopPadding: true)
        })
        return rows
    }

    enum Constants {
        enum Sequence {
            static let minRowCount = 1
            static let maxRowCount = 5
            static let rows = 0...maxRowCount
        }
    }
}
