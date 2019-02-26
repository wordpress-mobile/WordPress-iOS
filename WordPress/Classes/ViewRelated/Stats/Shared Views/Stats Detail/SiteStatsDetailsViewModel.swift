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
    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsReceipt: Receipt?
    private var insightsChangeReceipt: Receipt?

    private weak var insightsDelegate: SiteStatsInsightsDelegate?
    private weak var periodDelegate: SiteStatsPeriodDelegate?

    init(insightsDelegate: SiteStatsInsightsDelegate? = nil,
         periodDelegate: SiteStatsPeriodDelegate? = nil) {
        self.insightsDelegate = insightsDelegate
        self.periodDelegate = periodDelegate
    }

    func fetchDataFor(statSection: StatSection) {
        self.statSection = statSection
        guard let storeQuery = queryForStatSection(statSection) else {
            return
        }

        insightsReceipt = insightsStore.query(storeQuery)
        insightsChangeReceipt = insightsStore.onChange { [weak self] in
            self?.emitChange()
        }
    }

    func queryForStatSection(_ statSection: StatSection) -> InsightQuery? {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return .allFollowers
        default:
            return nil
        }
    }

    func tableViewModel() -> ImmuTable {
        guard let statSection = statSection else {
            return ImmuTable(sections: [])
        }

        var tableRows = [ImmuTableRow]()

        if StatSection.allInsights.contains(statSection),
            let insightRow = insightRow() {
            tableRows.append(insightRow)
        }

        if StatSection.allPeriods.contains(statSection),
            let periodRow = periodRow() {
            tableRows.append(periodRow)
        }

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    func insightRow() -> ImmuTableRow? {
        guard let insightsDelegate = insightsDelegate,
            let statSection = statSection else {
                return nil
        }

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            let selectedIndex = statSection == .insightsFollowersWordPress ? 0 : 1
            return TabbedTotalsStatsRow(tabsData: [tabDataForFollowerType(.insightsFollowersWordPress),
                                                   tabDataForFollowerType(.insightsFollowersEmail)],
                                        siteStatsInsightsDelegate: insightsDelegate,
                                        showTotalCount: true,
                                        selectedIndex: selectedIndex)
        default:
            return TopTotalsInsightStatsRow(itemSubtitle: statSection.itemSubtitle,
                                            dataSubtitle: statSection.dataSubtitle,
                                            dataRows: mockRows(),
                                            siteStatsInsightsDelegate: insightsDelegate)
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

    func periodRow() -> ImmuTableRow? {

        guard let periodDelegate = periodDelegate,
            let statSection = statSection else {
                return nil
        }

        switch statSection {
        case .periodCountries:
            return CountriesStatsRow(itemSubtitle: statSection.itemSubtitle,
                                     dataSubtitle: statSection.dataSubtitle,
                                     dataRows: mockRows(),
                                     siteStatsPeriodDelegate: periodDelegate)
        default:
            return TopTotalsPeriodStatsRow(itemSubtitle: statSection.itemSubtitle,
                                           dataSubtitle: statSection.dataSubtitle,
                                           dataRows: mockRows(),
                                           siteStatsPeriodDelegate: periodDelegate)
        }


    }

    // TODO: populate table with real data.
    // This is fake just to example the table.

    func mockRows() -> [StatsTotalRowData] {
        var dataRows = [StatsTotalRowData]()

        dataRows.append(StatsTotalRowData.init(name: "Row 1",
                                               data: 99999.abbreviatedString(),
                                               icon: Style.imageForGridiconType(.mySites)))


        dataRows.append(StatsTotalRowData.init(name: "Row 2",
                                               data: 666.abbreviatedString(),
                                               icon: Style.imageForGridiconType(.mySites)))

        dataRows.append(StatsTotalRowData.init(name: "Rows 3",
                                               data: 1010101010.abbreviatedString(),
                                               icon: Style.imageForGridiconType(.mySites)))

        return dataRows
    }
}
