import Foundation
import WordPressComStatsiOS
import WordPressFlux

/// The view model used by Stats Insights.
///
class SiteStatsInsightsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private let siteStatsInsightsDelegate: SiteStatsInsightsDelegate

    private let store: StatsInsightsStore
    private let insightsReceipt: Receipt
    private var changeReceipt: Receipt?

    // MARK: - Constructor

    init(insightsDelegate: SiteStatsInsightsDelegate, store: StatsInsightsStore = StoreContainer.shared.statsInsights) {
        self.siteStatsInsightsDelegate = insightsDelegate
        self.store = store
        insightsReceipt = store.query(.insights())

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        let latestPostSummaryRow = LatestPostSummaryRow(summaryData: store.getLatestPostSummary(),
                                                        siteStatsInsightsDelegate: siteStatsInsightsDelegate)
        tableRows.append(latestPostSummaryRow)

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

}
