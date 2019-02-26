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

    init(detailsDelegate: SiteStatsDetailsDelegate) {
        self.detailsDelegate = detailsDelegate
    }

    func fetchDataFor(statSection: StatSection) {
        self.statSection = statSection
        guard let storeQuery = queryForInsightStatSection(statSection) else {
            return
        }

        insightsReceipt = insightsStore.query(storeQuery)
        insightsChangeReceipt = insightsStore.onChange { [weak self] in
            self?.emitChange()
        }
    }

    func queryForInsightStatSection(_ statSection: StatSection) -> InsightQuery? {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return .allFollowers
        default:
            return nil
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

}

// MARK: - Private Extension

private extension SiteStatsDetailsViewModel {

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

}
