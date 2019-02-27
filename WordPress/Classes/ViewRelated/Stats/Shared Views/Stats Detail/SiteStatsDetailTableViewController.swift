import UIKit
import WordPressFlux

@objc protocol SiteStatsDetailsDelegate {
    @objc optional func tabbedTotalsCellUpdated()
}

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private var statType: StatType = .period

    private var viewModel: SiteStatsDetailsViewModel?
    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsChangeReceipt: Receipt?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    func configure(statSection: StatSection) {
        self.statSection = statSection
        statType = StatSection.allInsights.contains(statSection) ? .insights : .period

        title = statSection.title
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)

        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        initViewModel()
    }

}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func initViewModel() {
        viewModel = SiteStatsDetailsViewModel(detailsDelegate: self)

        guard let statSection = statSection else {
            return
        }

        viewModel?.fetchDataFor(statSection: statSection)

        if statType == .insights {
            insightsChangeReceipt = viewModel?.onChange { [weak self] in
                guard self?.storeIsFetching(statSection: statSection) == true else {
                    return
                }
                self?.refreshTableView()
            }
        } else {
            // TODO: add period receipt here
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [TabbedTotalsDetailStatsRow.self,
                TableFooterRow.self]
    }

    func storeIsFetching(statSection: StatSection) -> Bool {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return insightsStore.isFetchingFollowers
        default:
            return false
        }
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
        guard let statSection = statSection else {
            return
        }

        refreshControl?.beginRefreshing()

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            viewModel?.refreshFollowers()
        default:
            refreshControl?.endRefreshing()
        }

    }

    func applyTableUpdates() {
        tableView.beginUpdates()
        updateStatSectionForFilterChange()
        tableView.endUpdates()
    }

    func updateStatSectionForFilterChange() {
        statSection = (statSection == .insightsFollowersWordPress) ? .insightsFollowersEmail : .insightsFollowersWordPress
        initViewModel()
    }

}

// MARK: - SiteStatsDetailsDelegate Methods

extension SiteStatsDetailTableViewController: SiteStatsDetailsDelegate {

    func tabbedTotalsCellUpdated() {
        applyTableUpdates()
    }

}
