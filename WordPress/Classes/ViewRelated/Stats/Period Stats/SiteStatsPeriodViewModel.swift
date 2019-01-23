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

        tableRows.append(contentsOf: postsAndPagesTableRows())

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
    }

    struct PostsAndPages {
        static let itemSubtitle = NSLocalizedString("Title", comment: "Posts and Pages label for post/page title")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Posts and Pages label for number of views")
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

}
