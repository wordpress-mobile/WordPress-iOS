import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private let periodDelegate: SiteStatsPeriodDelegate
    private let store: StatsPeriodStore
    private let periodReceipt: Receipt
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Constructor

    init(store: StatsPeriodStore = StoreContainer.shared.statsPeriod,
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate) {
        self.periodDelegate = periodDelegate
        self.store = store
        periodReceipt = store.query(.periods(date: selectedDate, period: selectedPeriod))

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        tableRows.append(contentsOf: overviewTableRows())
        tableRows.append(contentsOf: postsAndPagesTableRows())
        tableRows.append(contentsOf: referrersTableRows())
        tableRows.append(contentsOf: clicksTableRows())
        tableRows.append(contentsOf: authorsTableRows())
        tableRows.append(contentsOf: countriesTableRows())
        tableRows.append(contentsOf: searchTermsTableRows())
        tableRows.append(contentsOf: publishedTableRows())
        tableRows.append(contentsOf: videosTableRows())
        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshPeriodData(withDate date: Date, forPeriod period: StatsPeriodUnit) {
        ActionDispatcher.dispatch(PeriodAction.refreshPeriodData(date: date, period: period))
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // MARK: - Create Table Rows

    func overviewTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: ""))

        // TODO: replace with real data
        let one = OverviewTabData(tabTitle: StatSection.periodOverviewViews.tabTitle, tabData: 85296, difference: -987, differencePercent: 5)
        let two = OverviewTabData(tabTitle: StatSection.periodOverviewVisitors.tabTitle, tabData: 741, difference: 22222, differencePercent: 50)
        let three = OverviewTabData(tabTitle: StatSection.periodOverviewLikes.tabTitle, tabData: 12345, difference: 75324, differencePercent: 27)
        let four = OverviewTabData(tabTitle: StatSection.periodOverviewComments.tabTitle, tabData: 987654321, difference: -258547987, differencePercent: -125999)
        tableRows.append(OverviewRow(tabsData: [one, two, three, four]))

        return tableRows
    }

    func postsAndPagesTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodPostsAndPages.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                           dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle,
                                           dataRows: postsAndPagesDataRows(),
                                           siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func postsAndPagesDataRows() -> [StatsTotalRowData] {
        let postsAndPages = store.getTopPostsAndPages()
        var dataRows = [StatsTotalRowData]()

        postsAndPages?.forEach { item in

            // TODO: when the backend provides the item type, set the icon to either pages or posts depending that.
            let icon = Style.imageForGridiconType(.posts)

            let dataBarPercent = StatsDataHelper.dataBarPercentForRow(item, relativeToRow: postsAndPages?.first)

            let row = StatsTotalRowData.init(name: item.label,
                                             data: item.value.displayString(),
                                             dataBarPercent: dataBarPercent,
                                             icon: icon,
                                             showDisclosure: true,
                                             disclosureURL: StatsDataHelper.disclosureUrlForItem(item),
                                             statSection: .periodPostsAndPages)

            dataRows.append(row)
        }

        return dataRows
    }

    func referrersTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodReferrers.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                 dataSubtitle: StatSection.periodReferrers.dataSubtitle,
                                                 dataRows: referrersDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func referrersDataRows() -> [StatsTotalRowData] {
        return store.getTopReferrers()?.map { StatsTotalRowData.init(name: $0.label,
                                                                  data: $0.value.displayString(),
                                                                  socialIconURL: $0.iconURL,
                                                                  showDisclosure: true,
                                                                  disclosureURL: StatsDataHelper.disclosureUrlForItem($0),
                                                                  childRows: childRowsForReferrers($0),
                                                                  statSection: .periodReferrers) }
            ?? []
    }

    func childRowsForReferrers(_ item: StatsItem) -> [StatsTotalRowData] {

        var childRows = [StatsTotalRowData]()

        guard let children = item.children as? [StatsItem] else {
            return childRows
        }

        children.forEach { child in
            var childsChildrenRows = [StatsTotalRowData]()
            if let childsChildren = child.children as? [StatsItem] {
                childsChildrenRows = childsChildren.map { StatsTotalRowData.init(name: $0.label,
                                                                                 data: $0.value.displayString(),
                                                                                 showDisclosure: true,
                                                                                 disclosureURL: StatsDataHelper.disclosureUrlForItem($0)) }
            }

            childRows.append(StatsTotalRowData.init(name: child.label,
                                                    data: child.value.displayString(),
                                                    showDisclosure: true,
                                                    disclosureURL: StatsDataHelper.disclosureUrlForItem(child),
                                                    childRows: childsChildrenRows,
                                                    statSection: .periodReferrers))
        }

        return childRows
    }

    func clicksTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodClicks.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                 dataSubtitle: StatSection.periodClicks.dataSubtitle,
                                                 dataRows: clicksDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func clicksDataRows() -> [StatsTotalRowData] {
        return store.getTopClicks()?.map { StatsTotalRowData.init(name: $0.label,
                                                     data: $0.value.displayString(),
                                                     showDisclosure: true,
                                                     disclosureURL: StatsDataHelper.disclosureUrlForItem($0),
                                                     childRows: childRowsForClicks($0),
                                                     statSection: .periodClicks) }
            ?? []
    }

    func childRowsForClicks(_ item: StatsItem) -> [StatsTotalRowData] {

        guard let children = item.children as? [StatsItem] else {
            return [StatsTotalRowData]()
        }

        return children.map { StatsTotalRowData.init(name: $0.label,
                                                     data: $0.value.displayString(),
                                                     showDisclosure: true,
                                                     disclosureURL: StatsDataHelper.disclosureUrlForItem($0)) }
    }

    func authorsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodAuthors.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                 dataSubtitle: StatSection.periodAuthors.dataSubtitle,
                                                 dataRows: authorsDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func authorsDataRows() -> [StatsTotalRowData] {
        let authors = store.getTopAuthors()
        return authors?.map { StatsTotalRowData.init(name: $0.label,
                                                     data: $0.value.displayString(),
                                                     dataBarPercent: StatsDataHelper.dataBarPercentForRow($0, relativeToRow: authors?.first),
                                                     userIconURL: $0.iconURL,
                                                     showDisclosure: true,
                                                     childRows: childRowsForAuthor($0),
                                                     statSection: .periodAuthors) }
            ?? []
    }

    func childRowsForAuthor(_ item: StatsItem) -> [StatsTotalRowData] {

        guard let children = item.children as? [StatsItem] else {
            return [StatsTotalRowData]()
        }

        return children.map { StatsTotalRowData.init(name: $0.label,
                                                     data: $0.value.displayString()) }
    }

    func countriesTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodCountries.title))
        tableRows.append(CountriesStatsRow(itemSubtitle: StatSection.periodCountries.itemSubtitle,
                                           dataSubtitle: StatSection.periodCountries.dataSubtitle,
                                           dataRows: countriesDataRows(),
                                           siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func countriesDataRows() -> [StatsTotalRowData] {
        return store.getTopCountries()?.map { StatsTotalRowData.init(name: $0.label,
                                                                     data: $0.value.displayString(),
                                                                     countryIconURL: $0.iconURL,
                                                                     statSection: .periodCountries) }
            ?? []
    }

    func searchTermsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodSearchTerms.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                 dataSubtitle: StatSection.periodSearchTerms.dataSubtitle,
                                                 dataRows: searchTermsDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func searchTermsDataRows() -> [StatsTotalRowData] {
        return store.getTopSearchTerms()?.map { StatsTotalRowData.init(name: $0.label,
                                                                       data: $0.value.displayString(),
                                                                       statSection: .periodSearchTerms) }
            ?? []
    }

    func publishedTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodPublished.title))
        tableRows.append(TopTotalsNoSubtitlesPeriodStatsRow(dataRows: publishedDataRows(),
                                                            siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func publishedDataRows() -> [StatsTotalRowData] {
        return store.getTopPublished()?.map { StatsTotalRowData.init(name: $0.label,
                                                                     data: "",
                                                                     showDisclosure: true,
                                                                     disclosureURL: StatsDataHelper.disclosureUrlForItem($0),
                                                                     statSection: .periodPublished) }
            ?? []
    }

    func videosTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodVideos.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                 dataSubtitle: StatSection.periodVideos.dataSubtitle,
                                                 dataRows: videosDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func videosDataRows() -> [StatsTotalRowData] {
        return store.getTopVideos()?.map { StatsTotalRowData.init(name: $0.label,
                                                                  data: $0.value.displayString(),
                                                                  mediaID: $0.itemID,
                                                                  icon: Style.imageForGridiconType(.video),
                                                                  showDisclosure: true,
                                                                  statSection: .periodVideos) }
            ?? []
    }

}
