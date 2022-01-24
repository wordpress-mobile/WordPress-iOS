import UIKit
import WordPressFlux


@objc protocol SiteStatsPeriodDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
}

protocol SiteStatsReferrerDelegate: AnyObject {
    func showReferrerDetails(_ data: StatsTotalRowData)
}

class SiteStatsPeriodTableViewController: UITableViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "SiteStatsDashboard"

    // MARK: - Properties

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var mediaService: MediaService = {
        return MediaService(managedObjectContext: mainContext)
    }()

    private lazy var blogService: BlogService = {
        return BlogService(managedObjectContext: mainContext)
    }()

    var selectedDate: Date?
    var selectedPeriod: StatsPeriodUnit? {
        didSet {

            guard selectedPeriod != nil else {
                return
            }

            clearExpandedRows()

            // If this is the first time setting the Period, need to initialize the view model.
            // Otherwise, just refresh the data.
            if oldValue == nil {
                initViewModel()
            } else {
                // If the oldValue is equal to the new value the overview cache is cleaned
                // This might happen only when a new date has been injected from the dashboard,
                // and the app will enter the foreground state.
                refreshData(resetOverviewCache: oldValue == selectedPeriod)
            }
        }
    }

    private let store = StoreContainer.shared.statsPeriod
    private var changeReceipt: Receipt?

    private var viewModel: SiteStatsPeriodViewModel?
    private var tableHeaderView: SiteStatsTableHeaderView?

    private let analyticsTracker = BottomScrollAnalyticsTracker()

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self, with: analyticsTracker)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        clearExpandedRows()
        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(userInitiatedRefresh), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableView.register(SiteStatsTableHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: SiteStatsTableHeaderView.defaultNibName)
        tableView.estimatedRowHeight = 500
        tableView.estimatedSectionHeaderHeight = SiteStatsTableHeaderView.estimatedHeight
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isMovingToParent {
            guard let date = selectedDate, let period = selectedPeriod else {
                return
            }
            addViewModelListeners()
            viewModel?.refreshPeriodOverviewData(withDate: date, forPeriod: period, resetOverviewCache: false)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteStatsTableHeaderView.defaultNibName) as? SiteStatsTableHeaderView else {
            return nil
        }

        cell.configure(date: selectedDate, period: selectedPeriod, delegate: self)
        cell.animateGhostLayers(viewModel?.isFetchingChart() == true)
        tableHeaderView = cell
        return cell
    }

}

extension SiteStatsPeriodTableViewController: StatsBarChartViewDelegate {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        if let intervalDate = viewModel?.chartDate(for: entryIndex) {
            tableHeaderView?.updateDate(with: intervalDate)
        }
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodTableViewController {

    // MARK: - View Model

    func initViewModel() {

        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }

        viewModel = SiteStatsPeriodViewModel(store: store,
                                             selectedDate: selectedDate,
                                             selectedPeriod: selectedPeriod,
                                             periodDelegate: self,
                                             referrerDelegate: self)
        viewModel?.statsBarChartViewDelegate = self
        addViewModelListeners()
        viewModel?.startFetchingOverview()
    }

    func addViewModelListeners() {
        if changeReceipt != nil {
            return
        }

        changeReceipt = viewModel?.onChange { [weak self] in
            self?.refreshTableView()
        }
    }

    func removeViewModelListeners() {
        changeReceipt = nil
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [PeriodEmptyCellHeaderRow.self,
                CellHeaderRow.self,
                TopTotalsPeriodStatsRow.self,
                TopTotalsNoSubtitlesPeriodStatsRow.self,
                CountriesStatsRow.self,
                CountriesMapRow.self,
                OverviewRow.self,
                TableFooterRow.self,
                StatsErrorRow.self,
                StatsGhostChartImmutableRow.self,
                StatsGhostTopImmutableRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()

        refreshControl?.endRefreshing()

        if viewModel.fetchingFailed() {
            displayFailureViewIfNecessary()
        }
    }

    @objc func userInitiatedRefresh() {
        clearExpandedRows()
        refreshControl?.beginRefreshing()
        refreshData()
    }

    func refreshData(resetOverviewCache: Bool = false) {
        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod,
            viewIsVisible() else {
                refreshControl?.endRefreshing()
                return
        }
        addViewModelListeners()
        viewModel?.refreshPeriodOverviewData(withDate: selectedDate, forPeriod: selectedPeriod, resetOverviewCache: resetOverviewCache)
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
        })
    }

    func clearExpandedRows() {
        StatsDataHelper.clearExpandedPeriods()
    }

    func viewIsVisible() -> Bool {
        return isViewLoaded && view.window != nil
    }
}

// MARK: - NoResultsViewHost

extension SiteStatsPeriodTableViewController: NoResultsViewHost {
    private func displayFailureViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        configureAndDisplayNoResults(on: tableView,
                                     title: NoResultConstants.errorTitle,
                                     subtitle: NoResultConstants.errorSubtitle,
                                     buttonTitle: NoResultConstants.refreshButtonTitle, customizationBlock: { [weak self] noResults in
                                        noResults.delegate = self
                                        if !noResults.isReachable {
                                            noResults.resetButtonText()
                                        }
                                     })
    }

    private enum NoResultConstants {
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let errorSubtitle = NSLocalizedString("There was a problem loading your data, refresh your page to try again.", comment: "The loading view subtitle displayed when an error occurred")
        static let refreshButtonTitle = NSLocalizedString("Refresh", comment: "The loading view button title displayed when an error occurred")
    }
}

// MARK: - NoResultsViewControllerDelegate methods

extension SiteStatsPeriodTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        hideNoResults()
        refreshData()
    }
}

// MARK: - SiteStatsPeriodDelegate Methods

extension SiteStatsPeriodTableViewController: SiteStatsPeriodDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "site_stats_period")
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID, let blog = Blog.lookup(withID: siteID, in: mainContext) else {
            DDLogInfo("Unable to get blog when trying to show media from Stats.")
            return
        }

        mediaService.getMediaWithID(mediaID, in: blog, success: { (media) in
            let viewController = MediaItemViewController(media: media)
            self.navigationController?.pushViewController(viewController, animated: true)
        }, failure: { (error) in
            DDLogInfo("Unable to get media when trying to show from Stats: \(error.localizedDescription)")
        })
    }

    func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool) {
        if didSelectRow {
            applyTableUpdates()
        }
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allPeriods.contains(statSection) else {
            return
        }

        removeViewModelListeners()

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection,
                                            selectedDate: selectedDate,
                                            selectedPeriod: selectedPeriod)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        removeViewModelListeners()

        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }
}

// MARK: - SiteStatsReferrerDelegate

extension SiteStatsPeriodTableViewController: SiteStatsReferrerDelegate {
    func showReferrerDetails(_ data: StatsTotalRowData) {
        show(ReferrerDetailsTableViewController(data: data), sender: nil)
    }
}

// MARK: - SiteStatsTableHeaderDelegate Methods

extension SiteStatsPeriodTableViewController: SiteStatsTableHeaderDateButtonDelegate {
    func dateChangedTo(_ newDate: Date?) {
        selectedDate = newDate
        refreshData()
    }

    func didTouchHeaderButton(forward: Bool) {
        if let intervalDate = viewModel?.updateDate(forward: forward) {
            tableHeaderView?.updateDate(with: intervalDate)
        }
    }
}
