import UIKit
import WordPressFlux

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?

    private var viewModel: SiteStatsDetailsViewModel?
    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsChangeReceipt: Receipt?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    func configure(statSection: StatSection,
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil,
                   siteStatsPeriodDelegate: SiteStatsPeriodDelegate? = nil) {
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsPeriodDelegate = siteStatsPeriodDelegate

        title = statSection.title
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        initViewModel()
    }

}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func initViewModel() {
        viewModel = SiteStatsDetailsViewModel(insightsDelegate: siteStatsInsightsDelegate)

        guard let statSection = statSection else {
            return
        }

        viewModel?.fetchDataFor(statSection: statSection)

        insightsChangeReceipt = viewModel?.onChange { [weak self] in
            guard self?.storeIsFetching(statSection: statSection) == false else {
                return
            }
            self?.refreshTableView()
        }
    }

    func storeIsFetching(statSection: StatSection) -> Bool {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return insightsStore.isFetchingFollowers
        default:
            return false
        }
    }


    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [TopTotalsInsightStatsRow.self,
                TabbedTotalsStatsRow.self,
                TopTotalsPeriodStatsRow.self,
                CountriesStatsRow.self,
                TableFooterRow.self]
    }

}
