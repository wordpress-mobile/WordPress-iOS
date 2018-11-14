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
    private var insightsToShow = [InsightType]()

    // MARK: - Constructor

    init(insightsToShow: [InsightType],
         insightsDelegate: SiteStatsInsightsDelegate,
         store: StatsInsightsStore = StoreContainer.shared.statsInsights) {
        self.siteStatsInsightsDelegate = insightsDelegate
        self.insightsToShow = insightsToShow
        self.store = store
        insightsReceipt = store.query(.insights())

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        insightsToShow.forEach { insightType in
            switch insightType {
            case .latestPostSummary:
                tableRows.append(LatestPostSummaryRow(summaryData: store.getLatestPostSummary(),
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
            case .allTimeStats:
                DDLogDebug("Show \(insightType) here.")
            case .followersTotals:
                DDLogDebug("Show \(insightType) here.")
            case .mostPopularDayAndHour:
                DDLogDebug("Show \(insightType) here.")
            case .tagsAndCategories:
                DDLogDebug("Show \(insightType) here.")
            case .annualSiteStats:
                DDLogDebug("Show \(insightType) here.")
            case .comments:
                DDLogDebug("Show \(insightType) here.")
            case .followers:
                DDLogDebug("Show \(insightType) here.")
            case .todaysStats:
                DDLogDebug("Show \(insightType) here.")
            case .postingActivity:
                DDLogDebug("Show \(insightType) here.")
            case .publicize:
                DDLogDebug("Show \(insightType) here.")
            }
        }

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshInsights() {
        ActionDispatcher.dispatch(InsightAction.refreshInsights())
    }

}
