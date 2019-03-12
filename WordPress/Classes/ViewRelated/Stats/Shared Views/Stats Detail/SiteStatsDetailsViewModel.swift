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
                                                      dataRows: createTagsAndCategoriesRows(),
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
        switch statSection {
        case .periodPostsAndPages:
            guard let selectedDate = selectedDate,
                let selectedPeriod = selectedPeriod else {
                    return nil
            }
            return .allPostsAndPages(date: selectedDate, period: selectedPeriod)
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

    func createTagsAndCategoriesRows() -> [StatsTotalRowData] {
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

}
