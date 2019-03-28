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

    init(detailsDelegate: SiteStatsDetailsDelegate) {
        self.detailsDelegate = detailsDelegate
    }

    func fetchDataFor(statSection: StatSection, selectedDate: Date? = nil, selectedPeriod: StatsPeriodUnit? = nil) {
        self.statSection = statSection
        self.selectedDate = selectedDate
        self.selectedPeriod = selectedPeriod

        if StatSection.allInsights.contains(statSection) {
            guard let storeQuery = queryForInsightStatSection(statSection) else {
                return
            }

            insightsReceipt = insightsStore.query(storeQuery)
            insightsChangeReceipt = insightsStore.onChange { [weak self] in
                self?.emitChange()
            }
        } else {
            guard let storeQuery = queryForPeriodStatSection(statSection) else {
                return
            }

            periodReceipt = periodStore.query(storeQuery)
            periodChangeReceipt = periodStore.onChange { [weak self] in
                self?.emitChange()
            }
        }
    }

    func tableViewModel() -> ImmuTable {

        guard let statSection = statSection,
            let detailsDelegate = detailsDelegate else {
                return ImmuTable(sections: [])
        }

        var tableRows = [ImmuTableRow]()

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            let selectedIndex = statSection == .insightsFollowersWordPress ? 0 : 1
            tableRows.append(TabbedTotalsDetailStatsRow(tabsData: [tabDataForFollowerType(.insightsFollowersWordPress),
                                                                   tabDataForFollowerType(.insightsFollowersEmail)],
                                                        siteStatsDetailsDelegate: detailsDelegate,
                                                        showTotalCount: true,
                                                        selectedIndex: selectedIndex))
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            let selectedIndex = statSection == .insightsCommentsAuthors ? 0 : 1
            tableRows.append(TabbedTotalsDetailStatsRow(tabsData: [tabDataForCommentType(.insightsCommentsAuthors),
                                                                   tabDataForCommentType(.insightsCommentsPosts)],
                                                        siteStatsDetailsDelegate: detailsDelegate,
                                                        showTotalCount: false,
                                                        selectedIndex: selectedIndex))
        case .insightsTagsAndCategories:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.insightsTagsAndCategories.itemSubtitle,
                                                      dataSubtitle: StatSection.insightsTagsAndCategories.dataSubtitle,
                                                      dataRows: tagsAndCategoriesRows(),
                                                      siteStatsDetailsDelegate: detailsDelegate))
        case .periodPostsAndPages:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                                     dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle,
                                                     dataRows: postsAndPagesRows(),
                                                     siteStatsDetailsDelegate: detailsDelegate))
        case .periodSearchTerms:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                     dataSubtitle: StatSection.periodSearchTerms.dataSubtitle,
                                                     dataRows: searchTermsRows(),
                                                     siteStatsDetailsDelegate: detailsDelegate))
        case .periodVideos:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                     dataSubtitle: StatSection.periodVideos.dataSubtitle,
                                                     dataRows: videosRows(),
                                                     siteStatsDetailsDelegate: detailsDelegate))
        case .periodClicks:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                     dataSubtitle: StatSection.periodClicks.dataSubtitle,
                                                     dataRows: clicksRows(),
                                                     siteStatsDetailsDelegate: detailsDelegate))
        case .periodAuthors:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                     dataSubtitle: StatSection.periodAuthors.dataSubtitle,
                                                     dataRows: authorsRows(),
                                                     siteStatsDetailsDelegate: detailsDelegate))
        case .periodReferrers:
            tableRows.append(TopTotalsDetailStatsRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                     dataSubtitle: StatSection.periodReferrers.dataSubtitle,
                                                     dataRows: referrersRows(),
                                                     siteStatsDetailsDelegate: detailsDelegate))
        case .periodCountries:
            tableRows.append(CountriesDetailStatsRow(itemSubtitle: StatSection.periodCountries.itemSubtitle,
                                                     dataSubtitle: StatSection.periodCountries.dataSubtitle,
                                                     dataRows: countriesRows()))
        case .periodPublished:
            tableRows.append(TopTotalsNoSubtitlesPeriodDetailStatsRow(dataRows: publishedRows(),
                                                                      siteStatsDetailsDelegate: detailsDelegate))
        default:
            break
        }

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshFollowers() {
        ActionDispatcher.dispatch(InsightAction.refreshFollowers())
    }

    func refreshComments() {
        ActionDispatcher.dispatch(InsightAction.refreshComments())
    }

    func refreshTagsAndCategories() {
        ActionDispatcher.dispatch(InsightAction.refreshTagsAndCategories())
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

}

// MARK: - Private Extension

private extension SiteStatsDetailsViewModel {

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

    func tabDataForFollowerType(_ followerType: StatSection) -> TabData {
        let tabTitle = followerType.tabTitle
        var followers: [StatsItem]?
        var totalFollowers: Int?

        switch followerType {
        case .insightsFollowersWordPress:
            followers = insightsStore.getAllDotComFollowers()
            totalFollowers = insightsStore.getDotComFollowers()?.dotComFollowersCount
        case .insightsFollowersEmail:
            followers = insightsStore.getAllEmailFollowers()
            totalFollowers = insightsStore.getEmailFollowers()?.emailFollowersCount
        default:
            break
        }

        let totalCount = String(format: followerType.totalFollowers, (totalFollowers ?? 0).abbreviatedString())

        let followersData = followers?.compactMap {
            return StatsTotalRowData(name: $0.label,
                                     data: $0.value,
                                     userIconURL: $0.iconURL,
                                     statSection: followerType)
        }

        return TabData(tabTitle: tabTitle,
                       itemSubtitle: followerType.itemSubtitle,
                       dataSubtitle: followerType.dataSubtitle,
                       totalCount: totalCount,
                       dataRows: followersData ?? [])
    }

    func tabDataForCommentType(_ commentType: StatSection) -> TabData {

        // TODO: replace this Store call to get actual Authors and Posts comments
        // when the api supports it.
        let commentsInsight = insightsStore.getTopCommentsInsight()

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

    func tagsAndCategoriesRows() -> [StatsTotalRowData] {
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

    func postsAndPagesRows() -> [StatsTotalRowData] {
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
                                     dataBarPercent: Float($0.viewsCount) / Float(postsAndPages.first!.viewsCount),
                                     icon: icon,
                                     showDisclosure: true,
                                     disclosureURL: $0.postURL,
                                     statSection: .periodPostsAndPages)
        }
    }

    func searchTermsRows() -> [StatsTotalRowData] {
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

    func videosRows() -> [StatsTotalRowData] {
        return periodStore.getTopVideos()?.videos.map { StatsTotalRowData(name: $0.title,
                                                                          data: $0.playsCount.abbreviatedString(),
                                                                          mediaID: $0.postID as NSNumber,
                                                                          icon: Style.imageForGridiconType(.video),
                                                                          showDisclosure: true,
                                                                          statSection: .periodVideos) }
            ?? []
    }

    func clicksRows() -> [StatsTotalRowData] {
        return periodStore.getTopClicks()?.clicks.map { StatsTotalRowData(name: $0.title,
                                                                          data: $0.clicksCount.abbreviatedString(),
                                                                          showDisclosure: true,
                                                                          disclosureURL: $0.iconURL,
                                                                          childRows: $0.children.map { StatsTotalRowData(name: $0.title,
                                                                                                                         data: $0.clicksCount.abbreviatedString(),
                                                                                                                         showDisclosure: true,
                                                                                                                         disclosureURL: $0.clickedURL) },
                                                                          statSection: .periodClicks) }
            ?? []
    }

    func authorsRows() -> [StatsTotalRowData] {
        let authors = periodStore.getTopAuthors()?.topAuthors ?? []

        return authors.map { StatsTotalRowData(name: $0.name,
                                               data: $0.viewsCount.abbreviatedString(),
                                               dataBarPercent: Float($0.viewsCount) / Float(authors.first!.viewsCount),
                                               userIconURL: $0.iconURL,
                                               showDisclosure: true,
                                               childRows: $0.posts.map { StatsTotalRowData(name: $0.title, data: $0.viewsCount.abbreviatedString()) },
                                               statSection: .periodAuthors) }
    }

    func referrersRows() -> [StatsTotalRowData] {
        let referrers = periodStore.getTopReferrers()?.referrers ?? []

        func rowDataFromReferrer(referrer: StatsReferrer) -> StatsTotalRowData {
            return StatsTotalRowData(name: referrer.title,
                                     data: referrer.viewsCount.abbreviatedString(),
                                     socialIconURL: referrer.iconURL,
                                     showDisclosure: true,
                                     disclosureURL: referrer.url,
                                     childRows: referrer.children.map { rowDataFromReferrer(referrer: $0) },
                                     statSection: .periodReferrers)
        }

        return referrers.map { rowDataFromReferrer(referrer: $0) }
    }

    func countriesRows() -> [StatsTotalRowData] {
        return periodStore.getTopCountries()?.countries.map { StatsTotalRowData(name: $0.name,
                                                                                data: $0.viewsCount.abbreviatedString(),
                                                                                countryIconURL: nil, //$0.iconURL // TODO FIXME Move this from WPiOSStats
                                                                                statSection: .periodCountries) }
            ?? []
    }

    func publishedRows() -> [StatsTotalRowData] {
        return periodStore.getTopPublished()?.publishedPosts.map { StatsTotalRowData(name: $0.title,
                                                                                     data: "",
                                                                                     showDisclosure: true,
                                                                                     disclosureURL: $0.postURL,
                                                                                     statSection: .periodPublished) }
            ?? []
    }

}
