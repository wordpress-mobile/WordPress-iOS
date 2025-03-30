import UIKit
import Combine
import WordPressShared

final class StatsSubscribersViewController: SiteStatsBaseTableViewController {
    private let viewModel: StatsSubscribersViewModel
    private var cancellables: Set<AnyCancellable> = []

    private lazy var tableHandler: ImmuTableDiffableViewHandler = {
        return ImmuTableDiffableViewHandler(takeOver: self, with: nil)
    }()

    init(viewModel: StatsSubscribersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        tableStyle = .insetGrouped
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.viewMoreDelegate = self
        tableView.cellLayoutMarginsFollowReadableWidth = true
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addObservers()
        viewModel.addObservers()
        viewModel.refreshData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        removeObservers()
        viewModel.removeObservers()
    }

    private func addObservers() {
        viewModel.tableViewSnapshot
            .sink { [weak self] snapshot in
                guard let self else { return }

                self.tableHandler.diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &cancellables)
    }

    private func removeObservers() {
        cancellables = []
    }

    @objc func refreshData() {
        viewModel.refreshData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.refreshControl.endRefreshing()
        }
    }

    // MARK: - Table View

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [
            SubscriberChartRow.self,
            TopTotalsPeriodStatsRow.self,
            TotalInsightStatsRow.self,
            StatsGhostTopImmutableRow.self,
            StatsGhostLineChartRow.self,
            StatsGhostSingleValueRow.self,
            StatsErrorRow.self
        ]
    }
}

extension StatsSubscribersViewController: SiteStatsPeriodDelegate {
    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        switch statSection {
        case .subscribersList:
            guard let blog = RootViewCoordinator.sharedPresenter.currentlyVisibleBlog(),
                  let peopleViewController = PeopleViewController.controllerWithBlog(blog, selectedFilter: .followers) else { return }
            navigationController?.pushViewController(peopleViewController, animated: true)
            WPAnalytics.track(.statsSubscribersViewMoreTapped)
        case .subscribersEmailsSummary:
            let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
            detailTableViewController.configure(statSection: statSection)
            navigationController?.pushViewController(detailTableViewController, animated: true)
            WPAnalytics.track(.statsEmailsViewMoreTapped)
        default:
            break
        }
    }
}
