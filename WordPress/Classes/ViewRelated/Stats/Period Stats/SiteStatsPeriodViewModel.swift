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
        let postsAndPages = store.getTopPostsAndPages()
        var dataRows = [StatsTotalRowData]()

        postsAndPages?.forEach { item in

            let disclosureURL: URL? = {
                if let actions = item.actions,
                    let action = actions.first as? StatsItemAction {
                    return action.url
                }
                return nil
            }()

            // TODO: use Page or Post icon
            let icon = Style.imageForGridiconType(.folder)

            let row = StatsTotalRowData.init(name: item.label,
                                             data: item.value.displayString(),
                                             icon: icon,
                                             showDisclosure: true,
                                             disclosureURL: disclosureURL)

            dataRows.append(row)
        }

        return dataRows
    }

}
