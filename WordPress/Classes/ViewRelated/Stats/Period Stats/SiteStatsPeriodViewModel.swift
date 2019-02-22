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

        // TODO: add overview chart here
        tableRows.append(contentsOf: postsAndPagesTableRows())
        tableRows.append(contentsOf: referrersTableRows())
        tableRows.append(contentsOf: clicksTableRows())
        tableRows.append(contentsOf: authorsTableRows())
        // TODO: add countries here
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

    // MARK: - Period Stats strings

    struct PeriodHeaders {
        static let postsAndPages = NSLocalizedString("Posts and Pages", comment: "Period Stats 'Posts and Pages' header")
        static let referrers = NSLocalizedString("Referrers", comment: "Period Stats 'Referrers' header")
        static let clicks = NSLocalizedString("Clicks", comment: "Period Stats 'Clicks' header")
        static let authors = NSLocalizedString("Authors", comment: "Period Stats 'Authors' header")
        static let searchTerms = NSLocalizedString("Search Terms", comment: "Period Stats 'Search Terms' header")
        static let published = NSLocalizedString("Published", comment: "Period Stats 'Published' header")
        static let videos = NSLocalizedString("Videos", comment: "Period Stats 'Videos' header")
    }

    struct PostsAndPages {
        static let itemSubtitle = NSLocalizedString("Title", comment: "Posts and Pages label for post/page title")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Posts and Pages label for number of views")
    }

    struct Referrers {
        static let itemSubtitle = NSLocalizedString("Referrer", comment: "Referrers label for link title")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Referrers label for number of views")
    }

    struct Clicks {
        static let itemSubtitle = NSLocalizedString("Link", comment: "Clicks label for link title")
        static let dataSubtitle = NSLocalizedString("Clicks", comment: "Clicks label for number of clicks")
    }

    struct Authors {
        static let itemSubtitle = NSLocalizedString("Author", comment: "Authors label for post author")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Authors label for number of views")
    }

    struct SearchTerms {
        static let itemSubtitle = NSLocalizedString("Search Term", comment: "Search Terms label for search term")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Search Terms label for number of views")
    }

    struct Videos {
        static let itemSubtitle = NSLocalizedString("Title", comment: "Videos label for post/page title")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Videos label for number of views")
    }

    // MARK: - Create Table Rows

    func postsAndPagesTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: PeriodHeaders.postsAndPages))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: PostsAndPages.itemSubtitle,
                                           dataSubtitle: PostsAndPages.dataSubtitle,
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
                                             showDisclosure: true)

            dataRows.append(row)
        }

        return dataRows
    }

    func referrersTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: PeriodHeaders.referrers))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: Referrers.itemSubtitle,
                                                 dataSubtitle: Referrers.dataSubtitle,
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
            ?? [StatsTotalRowData]()
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
        tableRows.append(CellHeaderRow(title: PeriodHeaders.clicks))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: Clicks.itemSubtitle,
                                                 dataSubtitle: Clicks.dataSubtitle,
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
            ?? [StatsTotalRowData]()
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
        tableRows.append(CellHeaderRow(title: PeriodHeaders.authors))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: Authors.itemSubtitle,
                                                 dataSubtitle: Authors.dataSubtitle,
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
            ?? [StatsTotalRowData]()
    }

    func childRowsForAuthor(_ item: StatsItem) -> [StatsTotalRowData] {

        guard let children = item.children as? [StatsItem] else {
            return [StatsTotalRowData]()
        }

        return children.map { StatsTotalRowData.init(name: $0.label,
                                                     data: $0.value.displayString()) }
    }

    func searchTermsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: PeriodHeaders.searchTerms))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: SearchTerms.itemSubtitle,
                                                 dataSubtitle: SearchTerms.dataSubtitle,
                                                 dataRows: searchTermsDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func searchTermsDataRows() -> [StatsTotalRowData] {
        return store.getTopSearchTerms()?.map { StatsTotalRowData.init(name: $0.label, data: $0.value.displayString()) }
            ?? [StatsTotalRowData]()
    }

    func publishedTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: PeriodHeaders.published))
        tableRows.append(TopTotalsNoSubtitlesPeriodStatsRow(dataRows: publishedDataRows(),
                                                            siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func publishedDataRows() -> [StatsTotalRowData] {
        return store.getTopPublished()?.map { StatsTotalRowData.init(name: $0.label,
                                                                     data: "",
                                                                     showDisclosure: true,
                                                                     disclosureURL: StatsDataHelper.disclosureUrlForItem($0)) }
            ?? [StatsTotalRowData]()
    }

    func videosTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: PeriodHeaders.videos))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: Videos.itemSubtitle,
                                                 dataSubtitle: Videos.dataSubtitle,
                                                 dataRows: videosDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func videosDataRows() -> [StatsTotalRowData] {
        return store.getTopVideos()?.map { StatsTotalRowData.init(name: $0.label,
                                                                  data: $0.value.displayString(),
                                                                  mediaID: $0.itemID,
                                                                  icon: Style.imageForGridiconType(.video),
                                                                  showDisclosure: true) }
            ?? [StatsTotalRowData]()
    }

}
