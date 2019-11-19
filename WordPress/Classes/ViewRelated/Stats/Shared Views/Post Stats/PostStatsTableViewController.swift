import UIKit
import WordPressFlux

@objc protocol PostStatsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
}

class PostStatsTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private var postTitle: String?
    private var postURL: URL?
    private var postID: Int?
    private var selectedDate = StatsDataHelper.currentDateForSite()
    private var tableHeaderView: SiteStatsTableHeaderView?
    private typealias Style = WPStyleGuide.Stats
    private var viewModel: PostStatsViewModel?
    private let store = StoreContainer.shared.statsPeriod
    private var changeReceipt: Receipt?
    private let asyncLoadingActivated = Feature.enabled(.statsAsyncLoadingDWMY)

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Post Stats", comment: "Window title for Post Stats view.")
        refreshControl?.addTarget(self, action: #selector(userInitiatedRefresh), for: .valueChanged)
        Style.configureTable(tableView)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableView.register(SiteStatsTableHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: SiteStatsTableHeaderView.defaultNibName)
        initViewModel()
        if !asyncLoadingActivated {
            displayLoadingViewIfNecessary()
        }
        trackAccessEvent()
        addWillEnterForegroundObserver()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeWillEnterForegroundObserver()
    }

    func configure(postID: Int, postTitle: String?, postURL: URL?) {
        self.postID = postID
        self.postTitle = postTitle
        self.postURL = postURL
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteStatsTableHeaderView.defaultNibName) as? SiteStatsTableHeaderView else {
            return nil
        }

        let lastTwoWeeks = store.getPostStats(for: postID)?.lastTwoWeeks ?? []

        cell.configure(date: selectedDate,
                       period: .day,
                       delegate: self,
                       expectedPeriodCount: lastTwoWeeks.count,
                       mostRecentDate: store.getMostRecentDate(forPost: postID))
        if asyncLoadingActivated {
            cell.animateGhostLayers(viewModel?.isFetchingPostDetails() == true)
        }
        tableHeaderView = cell
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteStatsTableHeaderView.headerHeight()
    }

}

extension PostStatsTableViewController: StatsForegroundObservable {
    func reloadStatsData() {
        if let mostRecentDate = store.getMostRecentDate(forPost: postID),
            mostRecentDate < selectedDate {
            selectedDate = mostRecentDate
        }
        refreshData()
    }
}

// MARK: - Table Methods

private extension PostStatsTableViewController {

    func initViewModel() {

        guard let postID = postID else {
            return
        }

        if let mostRecentDate = store.getMostRecentDate(forPost: postID),
            mostRecentDate < selectedDate {
            selectedDate = mostRecentDate
        }

        viewModel = PostStatsViewModel(postID: postID,
                                       selectedDate: selectedDate,
                                       postTitle: postTitle,
                                       postURL: postURL,
                                       postStatsDelegate: self)
        if asyncLoadingActivated {
            refreshTableView()
        }

        changeReceipt = viewModel?.onChange { [weak self] in
            if let store = self?.store,
                store.isFetchingPostStats(for: self?.postID),
                self?.asyncLoadingActivated == false {
                    return
            }

            self?.refreshTableView()
        }

        viewModel?.statsBarChartViewDelegate = self
    }

    func trackAccessEvent() {
        var properties = [AnyHashable: Any]()

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            properties["blog_id"] = blogIdentifier
        }

        if let postIdentifier = postID {
            properties["post_id"] = postIdentifier
        }

        WPAppAnalytics.track(.statsSinglePostAccessed, withProperties: properties)
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        var rows: [ImmuTableRow.Type] = [PostStatsEmptyCellHeaderRow.self,
                                         CellHeaderRow.self,
                                         PostStatsTitleRow.self,
                                         OverviewRow.self,
                                         TopTotalsPostStatsRow.self,
                                         TableFooterRow.self]

        if asyncLoadingActivated {
            rows.append(contentsOf: [StatsGhostChartImmutableRow.self,
                                     StatsGhostTitleRow.self,
                                     StatsGhostTopImmutableRow.self])
        }
        return rows
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
        refreshControl?.endRefreshing()

        if viewModel.fetchDataHasFailed() {
            displayFailureViewIfNecessary()
        } else {
            if !asyncLoadingActivated {
                hideNoResults()
            }
        }
    }

    @objc func userInitiatedRefresh() {
        refreshControl?.beginRefreshing()
        refreshData()
    }

    func refreshData(forceUpdate: Bool = false) {
        guard let viewModel = viewModel,
            let postID = postID else {
            return
        }

        viewModel.refreshPostStats(postID: postID, selectedDate: selectedDate)
        if forceUpdate {
            tableHandler.viewModel = viewModel.tableViewModel()
        }
        if !asyncLoadingActivated {
            displayLoadingViewIfNecessary()
        }
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
        })
    }

}

// MARK: - PostStatsDelegate Methods

extension PostStatsTableViewController: PostStatsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool) {
        if didSelectRow {
            applyTableUpdates()
        }
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allPostStats.contains(statSection) else {
            return
        }

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection, postID: postID)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

}

// MARK: - StatsBarChartViewDelegate

extension PostStatsTableViewController: StatsBarChartViewDelegate {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        tableHeaderView?.statsBarChartValueSelected(statsBarChartView, entryIndex: entryIndex, entryCount: entryCount)
    }
}

// MARK: - SiteStatsTableHeaderDelegate Methods

extension PostStatsTableViewController: SiteStatsTableHeaderDelegate {

    func dateChangedTo(_ newDate: Date?) {
        guard let newDate = newDate else {
            return
        }

        selectedDate = newDate
        refreshData(forceUpdate: true)
    }
}

// MARK: - NoResultsViewHost

extension PostStatsTableViewController: NoResultsViewHost {
    private func displayLoadingViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        if noResultsViewController.view.superview != nil {
            updateNoResults(title: NoResultConstants.successTitle,
                            accessoryView: NoResultsViewController.loadingAccessoryView()) { [weak self] noResults in
                                noResults.delegate = self
                                noResults.hideImageView(false)
            }
            return
        }

        configureAndDisplayNoResults(on: tableView,
                                     title: NoResultConstants.successTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView()) { [weak self] noResults in
                                        noResults.delegate = self
                                        noResults.hideImageView(false)
        }
    }

    private func displayFailureViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        if asyncLoadingActivated {
            configureAndDisplayNoResults(on: tableView,
                                         title: NoResultConstants.errorTitle,
                                         subtitle: NoResultConstants.errorSubtitle,
                                         buttonTitle: NoResultConstants.refreshButtonTitle) { [weak self] noResults in
                                            noResults.delegate = self
                                            if !noResults.isReachable {
                                                noResults.resetButtonText()
                                            }
            }
        } else {
            updateNoResults(title: NoResultConstants.errorTitle,
                            subtitle: NoResultConstants.errorSubtitle,
                            buttonTitle: NoResultConstants.refreshButtonTitle) { [weak self] noResults in
                                noResults.delegate = self
                                noResults.hideImageView()
            }
        }
    }

    private enum NoResultConstants {
        static let successTitle = NSLocalizedString("Loading Stats...", comment: "The loading view title displayed while the service is loading")
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let errorSubtitle = NSLocalizedString("There was a problem loading your data, refresh your page to try again.", comment: "The loading view subtitle displayed when an error occurred")
        static let refreshButtonTitle = NSLocalizedString("Refresh", comment: "The loading view button title displayed when an error occurred")
    }
}

// MARK: - NoResultsViewControllerDelegate methods

extension PostStatsTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        refreshData()

        if asyncLoadingActivated {
            hideNoResults()
        }
    }
}
