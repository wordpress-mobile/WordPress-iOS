import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private let store: StatsPeriodStore
    private let periodReceipt: Receipt
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Constructor

    init(store: StatsPeriodStore = StoreContainer.shared.statsPeriod) {
        self.store = store
        periodReceipt = store.query(.periods)

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

    func refreshPeriodData() {
        ActionDispatcher.dispatch(PeriodAction.refreshPeriodData())
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // Period Stats strings

    struct PeriodHeaders {
        static let postsAndPages = NSLocalizedString("Posts and Pages", comment: "Period Stats 'Posts and Pages' header")
    }

    struct PostsAndPages {
        static let itemSubtitle = NSLocalizedString("Title", comment: "Posts and Pages label for post/page title")
        static let dataSubtitle = NSLocalizedString("Views", comment: "Posts and Pages label for number of views")
    }

    // Create Period Rows

    func postsAndPagesTableRows() -> [ImmuTableRow] {

        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: PeriodHeaders.postsAndPages))
        tableRows.append(TopTotalsStatsRow(itemSubtitle: PostsAndPages.itemSubtitle,
                                           dataSubtitle: PostsAndPages.dataSubtitle,
                                           dataRows: postsAndPagesDataRows(),
                                           siteStatsInsightsDelegate: nil))

        return tableRows
    }

    func postsAndPagesDataRows() -> [StatsTotalRowData] {

        var dataRows = [StatsTotalRowData]()

        // TODO: replace with real Pages and Posts data from the Store
        // let postsAndPages = store.getPostsAndPages()

        let icon = Style.imageForGridiconType(.folder)

        for count in 1...10 {
            let row = StatsTotalRowData.init(name: "Row \(count)" ,
                                             data: "666",
                                             icon: icon,
                                             showDisclosure: true)

            dataRows.append(row)
        }

        return dataRows
    }

}
