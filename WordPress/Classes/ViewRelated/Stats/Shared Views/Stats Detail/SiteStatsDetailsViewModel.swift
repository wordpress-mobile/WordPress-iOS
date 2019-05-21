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

            insightsReceipt = insightsStore.query(storeQuery)
            insightsChangeReceipt = insightsStore.onChange { [weak self] in
                self?.emitChange()
            }
        case let statSection where StatSection.allPeriods.contains(statSection):
            guard let storeQuery = queryForPeriodStatSection(statSection) else {
                return
            }

            periodReceipt = periodStore.query(storeQuery)
            periodChangeReceipt = periodStore.onChange { [weak self] in
                self?.emitChange()
            }
        case let statSection where StatSection.allPostStats.contains(statSection):
            guard let postID = postID else {
                return
            }

            periodReceipt = periodStore.query(.postStats(postID: postID))
            periodChangeReceipt = periodStore.onChange { [weak self] in
                self?.emitChange()
            }
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

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {
        guard let statSection = statSection,
            let detailsDelegate = detailsDelegate else {
                return ImmuTable.Empty
        }

        if fetchDataHasFailed() {
            return ImmuTable.Empty
        }

        var tableRows = [ImmuTableRow]()

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            let selectedIndex = statSection == .insightsFollowersWordPress ? 0 : 1
            let wpTabData = tabDataForFollowerType(.insightsFollowersWordPress)
            let emailTabData = tabDataForFollowerType(.insightsFollowersEmail)

            tableRows.append(DetailSubtitlesTabbedHeaderRow(tabsData: [wpTabData, emailTabData],
                                                            siteStatsDetailsDelegate: detailsDelegate,
                                                            showTotalCount: true,
                                                            selectedIndex: selectedIndex))

            let dataRows = statSection == .insightsFollowersWordPress ? wpTabData.dataRows : emailTabData.dataRows
            tableRows.append(contentsOf: tabbedRowsFrom(dataRows))
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            let selectedIndex = statSection == .insightsCommentsAuthors ? 0 : 1
            let authorsTabData = tabDataForCommentType(.insightsCommentsAuthors)
            let postsTabData = tabDataForCommentType(.insightsCommentsPosts)

            tableRows.append(DetailSubtitlesTabbedHeaderRow(tabsData: [authorsTabData, postsTabData],
                                                            siteStatsDetailsDelegate: detailsDelegate,
                                                            showTotalCount: false,
                                                            selectedIndex: selectedIndex))

            let dataRows = statSection == .insightsCommentsAuthors ? authorsTabData.dataRows : postsTabData.dataRows
            tableRows.append(contentsOf: tabbedRowsFrom(dataRows))
        case .insightsTagsAndCategories:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.insightsTagsAndCategories.itemSubtitle,
                                                      dataSubtitle: StatSection.insightsTagsAndCategories.dataSubtitle))
            tableRows.append(contentsOf: tagsAndCategoriesRows())
        case .periodPostsAndPages:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                                      dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle))
            tableRows.append(contentsOf: postsAndPagesRows())

        case .periodSearchTerms:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                     dataSubtitle: StatSection.periodSearchTerms.dataSubtitle))
            tableRows.append(contentsOf: searchTermsRows())
        case .periodVideos:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                     dataSubtitle: StatSection.periodVideos.dataSubtitle))
            tableRows.append(contentsOf: videosRows())
        case .periodClicks:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                      dataSubtitle: StatSection.periodClicks.dataSubtitle))
            tableRows.append(contentsOf: clicksRows())
        case .periodAuthors:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                      dataSubtitle: StatSection.periodAuthors.dataSubtitle))
            tableRows.append(contentsOf: authorsRows())
        case .periodReferrers:
            tableRows.append(DetailSubtitlesHeaderRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                      dataSubtitle: StatSection.periodReferrers.dataSubtitle))
            tableRows.append(contentsOf: referrersRows())
        case .periodCountries:
            tableRows.append(DetailSubtitlesCountriesHeaderRow(itemSubtitle: StatSection.periodCountries.itemSubtitle,
                                                     dataSubtitle: StatSection.periodCountries.dataSubtitle))
            tableRows.append(contentsOf: countriesRows())
        case .periodPublished:
            tableRows.append(contentsOf: publishedRows())
        case .postStatsMonthsYears:
            tableRows.append(DetailSubtitlesCountriesHeaderRow(itemSubtitle: StatSection.postStatsMonthsYears.itemSubtitle,
                                                               dataSubtitle: StatSection.postStatsMonthsYears.dataSubtitle))
            tableRows.append(contentsOf: postStatsRows())
        case .postStatsAverageViews:
            tableRows.append(DetailSubtitlesCountriesHeaderRow(itemSubtitle: StatSection.postStatsAverageViews.itemSubtitle,
                                                               dataSubtitle: StatSection.postStatsAverageViews.dataSubtitle))
            tableRows.append(contentsOf: postStatsRows(forAverages: true))
        default:
            break
        }

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
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
            totalFollowers = insightsStore.getDotComFollowers()?.dotComFollowersCount
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

    // MARK: - Posts and Pages

    func postsAndPagesRows() -> [DetailDataRow] {
        return dataRowsFor(postsAndPagesRowData())
    }

    func postsAndPagesRowData() -> [StatsTotalRowData] {
        let postsAndPages = periodStore.getTopPostsAndPages()?.topPosts ?? []

        return postsAndPages.map {
            let icon: UIImage?

            switch $0.kind {
            case .homepage:
                icon = Style.imageForGridiconType(.house)
            case .page:
                icon = Style.imageForGridiconType(.pages)
            case .post:
                icon = Style.imageForGridiconType(.posts)
            case .unknown:
                icon = Style.imageForGridiconType(.posts)
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

    func searchTermsRows() -> [DetailDataRow] {
        return dataRowsFor(searchTermsRowData())
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

    func videosRows() -> [DetailDataRow] {
        return dataRowsFor(videosRowData())
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

    func clicksRows() -> [ImmuTableRow] {
        return expandableDataRowsFor(clicksRowData())
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

    func authorsRows() -> [ImmuTableRow] {
        return expandableDataRowsFor(authorsRowData())
    }

    func authorsRowData() -> [StatsTotalRowData] {
        let authors = periodStore.getTopAuthors()?.topAuthors ?? []

        return authors.map {
            StatsTotalRowData(name: $0.name,
                              data: $0.viewsCount.abbreviatedString(),
                              dataBarPercent: Float($0.viewsCount) / Float(authors.first!.viewsCount),
                              userIconURL: $0.iconURL,
                              showDisclosure: true,
                              childRows: $0.posts.map { StatsTotalRowData(name: $0.title, data: $0.viewsCount.abbreviatedString()) },
                              statSection: .periodAuthors)
        }
    }

    // MARK: - Referrers

    func referrersRows() -> [ImmuTableRow] {
        return expandableDataRowsFor(referrersRowData())
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

    func countriesRows() -> [DetailDataRow] {
        return dataRowsFor(countriesRowData())
    }

    func countriesRowData() -> [StatsTotalRowData] {
        return periodStore.getTopCountries()?.countries.map { StatsTotalRowData(name: $0.name,
                                                                                data: $0.viewsCount.abbreviatedString(),
                                                                                icon: UIImage(named: $0.code),
                                                                                statSection: .periodCountries) }
            ?? []
    }

    // MARK: - Published

    func publishedRows() -> [DetailDataRow] {
        return dataRowsFor(publishedRowData())
    }

    func publishedRowData() -> [StatsTotalRowData] {
        return periodStore.getTopPublished()?.publishedPosts.map { StatsTotalRowData(name: $0.title,
                                                                                     data: "",
                                                                                     showDisclosure: true,
                                                                                     disclosureURL: $0.postURL,
                                                                                     statSection: .periodPublished) }
            ?? []
    }

    // MARK: - Post Stats

    func postStatsRows(forAverages: Bool = false) -> [ImmuTableRow] {
        return expandableDataRowsFor(postStatsRowData(forAverages: forAverages))
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

    func dataRowsFor(_ rowsData: [StatsTotalRowData]) -> [DetailDataRow] {
        var detailDataRows = [DetailDataRow]()

        for (idx, rowData) in rowsData.enumerated() {
            detailDataRows.append(DetailDataRow(rowData: rowData,
                                                detailsDelegate: detailsDelegate,
                                                hideSeparator: idx == rowsData.endIndex-1))
        }

        return detailDataRows
    }

    func expandableDataRowsFor(_ rowsData: [StatsTotalRowData]) -> [ImmuTableRow] {
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

            let isLastRow = idx == rowsData.endIndex-1

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

}
